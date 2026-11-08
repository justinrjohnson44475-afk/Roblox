--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Economy = require(Shared.Economy)
local Shift = require(Shared.Shift)
local RateLimit = require(Shared.RateLimit)
local DataService = require(script.Parent.DataService)
local Purchases = require(script.Parent.Purchases)
local Analytics = require(script.Parent.Analytics)
local World = require(script.Parent.World)

local remotes = Instance.new("Folder")
remotes.Name = "HarborRemotes"
remotes.Parent = ReplicatedStorage
local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes
local actionEvent = Instance.new("RemoteEvent")
actionEvent.Name = "Action"
actionEvent.Parent = remotes
local sessions = {}
local world = World.build(Config)
local shift = Shift.new(Config, os.clock())
local celebrationEnds = 0
local closing = false

local function send(player, notice)
	local session = sessions[player]
	local profile = DataService.get(player)
	if not session or not profile or not player.Parent then
		return
	end
	local project = Config.Projects[shift.Index]
	stateEvent:FireClient(player, {
		Tokens = profile.Tokens,
		Donated = profile.Donated,
		Repairs = profile.Repairs,
		Owned = profile.Owned,
		Equipped = profile.Equipped,
		Carried = session.Carried,
		Project = if project then project.Name else "Harbor restored! A new shift begins soon",
		Progress = shift.Progress,
		Required = if project then project.Required else 0,
		Seconds = math.max(
			0,
			math.ceil((if shift.Complete then celebrationEnds else shift.EndsAt) - os.clock())
		),
		Complete = shift.Complete,
		Notice = notice,
		SaveMode = DataService.mode(),
		SaveWarning = player:GetAttribute("SaveWarning") == true,
		Supporter = player:GetAttribute("HarborSupporter") == true,
	})
end
local function broadcast()
	World.render(world, shift, Config)
	for player in sessions do
		send(player)
	end
end
local function near(player, position): boolean
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	return root ~= nil
		and humanoid ~= nil
		and humanoid.Health > 0
		and (root.Position - position).Magnitude <= Config.InteractionDistance
end
local function ready(player, position)
	local session = sessions[player]
	if closing or not session or not DataService.get(player) then
		return nil
	end
	if position and not near(player, position) then
		return nil
	end
	if not RateLimit.allow(session.Limits, "interact", os.clock(), 0.55) then
		return nil
	end
	return session
end
local function lantern(player)
	local profile = DataService.get(player)
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not profile or not root then
		return
	end
	local old = character:FindFirstChild("HarborLantern")
	if old then
		old:Destroy()
	end
	local rgb = Config.Cosmetics[profile.Equipped].RGB
	local color = Color3.fromRGB(rgb[1], rgb[2], rgb[3])
	local orb = Instance.new("Part")
	orb.Name = "HarborLantern"
	orb.Shape = Enum.PartType.Ball
	orb.Size = Vector3.new(0.65, 0.65, 0.65)
	orb.CanCollide = false
	orb.CanTouch = false
	orb.CanQuery = false
	orb.Massless = true
	orb.Material = Enum.Material.Neon
	orb.Color = color
	orb.CFrame = root.CFrame * CFrame.new(1.5, 0, 0)
	orb.Parent = character
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = orb
	weld.Parent = orb
	if player:GetAttribute("HarborSupporter") then
		local trim = Instance.new("Part")
		trim.Name = "OceanTrim"
		trim.Size = Vector3.new(0.8, 0.12, 0.8)
		trim.Color = Color3.fromRGB(75, 160, 255)
		trim.Material = Enum.Material.Neon
		trim.CanCollide = false
		trim.CanTouch = false
		trim.CanQuery = false
		trim.Massless = true
		trim.CFrame = orb.CFrame
		trim.Parent = orb
		local trimWeld = Instance.new("WeldConstraint")
		trimWeld.Part0 = orb
		trimWeld.Part1 = trim
		trimWeld.Parent = trim
	end
end
for _, supply in world.Supplies do
	supply.Prompt.Triggered:Connect(function(player)
		local session = ready(player, supply.Part.Position)
		if not session then
			return
		end
		if session.Carried >= Config.Capacity then
			send(player, "Bag full — contribute to the current repair")
			return
		end
		local now = os.clock()
		if now < supply.AvailableAt then
			return
		end
		supply.AvailableAt = now + Config.PickupCooldown
		supply.Prompt.Enabled = false
		supply.Part.Transparency = 0.65
		session.Carried += 1
		send(player, "Supply recovered")
	end)
end
for index, project in world.Projects do
	project.Prompt.Triggered:Connect(function(player)
		local session = ready(player, project.Part.Position)
		if not session or shift.Complete or os.clock() >= shift.EndsAt or shift.Index ~= index then
			return
		end
		local profile = DataService.get(player)
		if not profile then
			return
		end
		if session.Carried == 0 then
			send(player, "Recover supplies from teal crates first")
			return
		end
		local first = profile.Donated == 0
		local amount = Economy.deposit(
			profile,
			session.Carried,
			Config.Projects[index].Required - shift.Progress,
			Config
		)
		session.Carried -= amount
		local completed, participants = Shift.add(shift, player.UserId, amount, Config)
		if first then
			Analytics.record(player, "FirstContribution")
		end
		if completed then
			for participant in sessions do
				if participants[participant.UserId] then
					local participantProfile = DataService.get(participant)
					if participantProfile then
						participantProfile.Repairs += 1
						Analytics.record(participant, "RepairCompleted")
					end
				end
			end
		end
		if shift.Complete then
			celebrationEnds = os.clock() + Config.CelebrationSeconds
		end
		broadcast()
		send(
			player,
			string.format("Contributed %d supplies · +%d tokens", amount, amount * Config.TokensPerSupply)
		)
	end)
end

actionEvent.OnServerEvent:Connect(function(player, action, item)
	local session = sessions[player]
	if closing or not session or type(action) ~= "string" or #action > 24 then
		return
	end
	if not RateLimit.allow(session.Limits, "remote", os.clock(), 0.4) then
		return
	end
	local profile = DataService.get(player)
	if not profile then
		return
	end
	if action == "state" then
		send(player)
	elseif action == "equip" then
		local ok, message = Economy.equip(profile, item, Config)
		if ok then
			lantern(player)
		end
		send(player, message)
	elseif action == "supporter" then
		local _, message = Purchases.prompt(player)
		send(player, message)
	end
end)
local function added(player)
	if closing or sessions[player] then
		return
	end
	sessions[player] = { Carried = 0, Limits = {} }
	local function characterAdded(character)
		local session = sessions[player]
		if session then
			session.Carried = 0
		end
		if character:WaitForChild("HumanoidRootPart", 10) then
			lantern(player)
		end
		send(player)
	end
	player.CharacterAdded:Connect(characterAdded)
	player:GetAttributeChangedSignal("HarborSupporter"):Connect(function()
		lantern(player)
		send(player)
	end)
	if not DataService.load(player) then
		sessions[player] = nil
		player:Kick("Your progress could not be loaded safely. Please retry shortly.")
		return
	end
	if not player.Parent then
		DataService.save(player, true)
		sessions[player] = nil
		return
	end
	if player.Character then
		task.spawn(characterAdded, player.Character)
	end
	send(player, "Welcome! Recover supplies, then contribute at the glowing repair station")
	task.spawn(Purchases.refresh, player)
end
Players.PlayerAdded:Connect(added)
Players.PlayerRemoving:Connect(function(player)
	sessions[player] = nil
	Purchases.remove(player)
	DataService.save(player, true)
end)
for _, player in Players:GetPlayers() do
	task.spawn(added, player)
end
broadcast()
task.spawn(function()
	while not closing do
		task.wait(1)
		local now = os.clock()
		for _, supply in world.Supplies do
			if now >= supply.AvailableAt then
				supply.Prompt.Enabled = true
				supply.Part.Transparency = 0
			end
		end
		if (shift.Complete and now >= celebrationEnds) or (not shift.Complete and now >= shift.EndsAt) then
			shift = Shift.new(Config, now)
		end
		broadcast()
	end
end)
task.spawn(function()
	while not closing do
		task.wait(Config.SaveSeconds)
		if closing then
			break
		end
		for player in sessions do
			task.spawn(DataService.save, player, false)
		end
	end
end)
game:BindToClose(function()
	closing = true
	local pending = 0
	for player in sessions do
		pending += 1
		task.spawn(function()
			DataService.save(player, true)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
