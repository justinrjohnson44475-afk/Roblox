--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
if Shared:GetAttribute("AscensionEnabled") then
	return
end
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local Combat = require(Shared.Combat)
local EnemyAI = require(Shared.EnemyAI)
local RateLimit = require(Shared.RateLimit)
local Authority = require(Shared.Authority)
local Economy = require(Shared.Economy)
local DataService = require(script.Parent.DataService)
local Purchases = require(script.Parent.Purchases)
local Analytics = require(script.Parent.Analytics)
local World = require(script.Parent.World)
local Appearance = require(script.Parent.Appearance)
local map = workspace:WaitForChild("RiftwakeWorld")
local remotes = Instance.new("Folder")
remotes.Name = "RiftRemotes"
remotes.Parent = ReplicatedStorage
local function remote(name)
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end
local stateEvent, actionEvent, effects = remote("State"), remote("Action"), remote("Effects")
local enemiesFolder = Instance.new("Folder")
enemiesFolder.Name = "RiftEnemies"
enemiesFolder.Parent = workspace
local warningsFolder = Instance.new("Folder")
warningsFolder.Name = "AttackWarnings"
warningsFolder.Parent = workspace
local sessions, enemies = {}, {}
local closing = false
local stateAccumulator, tickAccumulator = 0, 0
local send
local function v(values)
	return Vector3.new(unpack(values))
end
local function flat(vector)
	return Vector3.new(vector.X, 0, vector.Z)
end
local function character(player)
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	local humanoid = c and c:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil, nil
	end
	return root, humanoid
end
local function profile(player)
	return DataService.get(player)
end
local function returnTo(player, destination)
	local s = sessions[player]
	local root = character(player)
	if not s or not root then
		return
	end
	local region = World.region(Config, destination)
	local position = if destination == "hub"
		then v(Config.Spawn)
		else v(region.Center) + Vector3.new(0, 5, 34)
	root.CFrame = CFrame.lookAt(position, position + Vector3.new(0, 0, -1))
	root.AssemblyLinearVelocity = Vector3.zero
	s.Region = destination
	s.LastPosition = position
	s.LastMoveAt = os.clock()
	s.Combat.Focus = 0
	if send then
		send(player, "Entered " .. region.Name)
	end
end
local function validLocation(player)
	local s = sessions[player]
	local root, humanoid = character(player)
	if not s or not root then
		return nil, nil
	end
	local region = World.region(Config, s.Region)
	local distance = flat(root.Position - v(region.Center)).Magnitude
	local now = os.clock()
	local displacement = if s.LastPosition then (root.Position - s.LastPosition).Magnitude else 0
	local movementValid = Authority.movement(displacement, math.max(0, now - s.LastMoveAt))
	if
		distance > region.Radius + 20
		or root.Position.Y < region.Center[2] - 12
		or root.Position.Y > region.Center[2] + 70
		or not movementValid
	then
		returnTo(player, "hub")
		return nil, nil
	end
	s.LastPosition = root.Position
	s.LastMoveAt = now
	return root, humanoid
end
local function appearance(player, heal)
	local p = profile(player)
	local root, humanoid = character(player)
	if not p or not root then
		return
	end
	local stats = Progression.stats(p, Config)
	local oldMaximum = humanoid.MaxHealth
	humanoid.MaxHealth = stats.Health
	humanoid.Health = if heal
		then stats.Health
		else math.min(stats.Health, humanoid.Health + math.max(0, stats.Health - oldMaximum))
	humanoid.WalkSpeed = if p.Path == "strider" then 20 else 17
	local color = Config.Cosmetics[p.Equipped].RGB
	Appearance.rig(
		player.Character,
		p.Form,
		Color3.fromRGB(unpack(color)),
		player:GetAttribute("HarborSupporter") == true
	)
end
send = function(player, notice)
	local s = sessions[player]
	local p = profile(player)
	if not s or not p or not player.Parent then
		return
	end
	local stats = Progression.stats(p, Config)
	local _, humanoid = character(player)
	local now = os.clock()
	local cooldowns = {}
	local lengths = {
		strike = 0.48 * stats.CooldownScale,
		dash = stats.DashCooldown,
		burst = 4 * stats.CooldownScale,
		overdrive = 14,
	}
	for key, length in lengths do
		cooldowns[key] = math.max(0, (s.Combat.Last[key] or -100) + length - now)
	end
	stateEvent:FireClient(player, {
		XP = p.XP,
		Level = stats.Level,
		NextXP = Progression.threshold(math.min(16, stats.Level + 1)),
		LevelXP = Progression.threshold(stats.Level),
		Shards = p.Shards,
		Cores = p.Cores,
		Form = p.Form,
		Path = p.Path,
		Upgrades = p.Upgrades,
		Clears = p.Clears,
		Owned = p.Owned,
		Equipped = p.Equipped,
		LegacyTokens = p.Tokens,
		Health = if humanoid then math.ceil(humanoid.Health) else 0,
		MaxHealth = stats.Health,
		Damage = stats.Damage,
		Focus = s.Combat.Focus,
		BurstCost = stats.BurstCost,
		Cooldowns = cooldowns,
		Region = s.Region,
		Goal = Progression.goal(p, Config),
		Notice = notice,
		SaveMode = DataService.mode(),
		SaveWarning = player:GetAttribute("SaveWarning") == true,
	})
end
local function notify(player, text)
	send(player, text)
end
local function warningPart(zone, color)
	local p = Instance.new("Part")
	p.Name = "ChargedAttack"
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = 0.56
	if zone.Shape == "line" then
		local delta = zone.To - zone.From
		p.Size = Vector3.new(zone.Radius * 2, 0.15, delta.Magnitude)
		p.CFrame = CFrame.lookAt((zone.From + zone.To) / 2, zone.To)
	else
		p.Shape = Enum.PartType.Cylinder
		p.Size = Vector3.new(0.15, zone.Radius * 2, zone.Radius * 2)
		p.CFrame = CFrame.new(zone.Position) * CFrame.Angles(0, 0, math.pi / 2)
	end
	p.Parent = warningsFolder
	return p
end
local function clearWarnings(e)
	for _, warning in e.Warnings or {} do
		warning:Destroy()
	end
	e.Warnings = {}
end
local function spawnEnemy(spawn)
	local def = Config.Enemies[spawn.Kind]
	local region = World.region(Config, spawn.Region)
	local marker = map[spawn.Region]["Spawn_" .. spawn.Id]
	local position = marker.Position + Vector3.new(0, (def.Scale - 1) * 3.4, 0)
	local model, core, label = Appearance.enemy(def, Color3.fromRGB(unpack(region.Color)))
	model.Name = spawn.Id
	model:SetAttribute("Kind", spawn.Kind)
	model:SetAttribute("Region", spawn.Region)
	model.Parent = enemiesFolder
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, math.pi, 0))
	local state = EnemyAI.new(def, os.clock())
	state.Model = model
	state.Core = core
	state.Label = label
	state.Position = position
	state.Home = position
	state.Spawn = spawn
	state.Warnings = {}
	state.Zones = {}
	state.RespawnAt = 0
	enemies[spawn.Id] = state
	return state
end
local function closestTarget(e)
	local chosen, chosenRoot, distance = nil, nil, math.huge
	for player, s in sessions do
		if s.Region == e.Spawn.Region and profile(player) then
			local root = character(player)
			if root then
				local d = flat(root.Position - e.Position).Magnitude
				if
					d < distance
					and EnemyAI.canAcquire(
						e,
						Config.Enemies[e.Spawn.Kind],
						d,
						flat(root.Position - e.Home).Magnitude
					)
				then
					chosen = player
					chosenRoot = root
					distance = d
				end
			end
		end
	end
	return chosen, chosenRoot, if chosen then distance else nil
end
local function pointInZone(position, zone)
	local point = flat(position)
	if zone.Shape == "circle" then
		return (point - flat(zone.Position)).Magnitude <= zone.Radius
	end
	local a, b = flat(zone.From), flat(zone.To)
	local segment = b - a
	local t = math.clamp((point - a):Dot(segment) / math.max(0.01, segment:Dot(segment)), 0, 1)
	return (point - (a + segment * t)).Magnitude <= zone.Radius
end
local function impact(e, def, zones)
	if e.Dead then
		return
	end
	for player, s in sessions do
		if s.Region == e.Spawn.Region and profile(player) then
			local root, humanoid = validLocation(player)
			if root and os.clock() > s.Combat.DodgeUntil then
				for _, zone in zones do
					if pointInZone(root.Position, zone) then
						humanoid:TakeDamage(def.Damage * (if e.Phase == 2 then 1.12 else 1))
						effects:FireClient(player, "hurt", root.Position, nil, def.Damage)
						send(player)
						break
					end
				end
			end
		end
	end
end
local function telegraph(e, def, targetRoot)
	clearWarnings(e)
	local facing = flat(targetRoot.Position - e.Position)
	if facing.Magnitude > 0.1 then
		e.Model:PivotTo(CFrame.lookAt(e.Position, e.Position + facing.Unit))
	end
	local region = World.region(Config, e.Spawn.Region)
	local floor = region.Center[2] + 1.4
	local from = Vector3.new(e.Position.X, floor, e.Position.Z)
	local target = Vector3.new(targetRoot.Position.X, floor, targetRoot.Position.Z)
	if e.Pattern == "lance" then
		local delta = target - from
		local direction = if delta.Magnitude > 0.1 then delta.Unit else Vector3.new(0, 0, 1)
		e.Zones = {
			{
				Shape = "line",
				From = from,
				To = from + direction * (def.Reach + 12),
				Radius = if def.Boss then 4.5 else 3.5,
			},
		}
	else
		e.Zones = { { Shape = "circle", Position = from, Radius = def.Radius } }
	end
	if e.Spawn.Kind == "astral_warden" and e.Phase == 2 then
		e.Zones = {}
		for _, offset in { Vector3.zero, Vector3.new(-11, 0, 7), Vector3.new(11, 0, 7) } do
			table.insert(e.Zones, { Shape = "circle", Position = target + offset, Radius = 8 })
		end
	end
	for _, zone in e.Zones do
		table.insert(e.Warnings, warningPart(zone, Color3.fromRGB(255, 158, 68)))
	end
	e.Model:SetAttribute("State", "windup")
	e.Core.Color = Color3.fromRGB(255, 184, 82)
end
local function defeat(e, def)
	clearWarnings(e)
	e.RespawnAt = os.clock() + def.Respawn
	e.Model:SetAttribute("State", "dead")
	for _, p in e.Model:GetDescendants() do
		if p:IsA("BasePart") then
			p.Transparency = 0.8
		end
	end
	for _, userId in Combat.recipients(e, os.clock()) do
		local player = Players:GetPlayerByUserId(userId)
		local s = player and sessions[player]
		local p = player and profile(player)
		local root = player and character(player)
		if
			p
			and s
			and root
			and Authority.reward(s.Region, e.Spawn.Region, flat(root.Position - e.Home).Magnitude, true)
		then
			local oldLevel = Progression.level(p.XP)
			local first = Progression.reward(p, e.Spawn.Kind, Config)
			if Progression.level(p.XP) > oldLevel then
				appearance(player, false)
				effects:FireClient(player, "level", root.Position)
			end
			if def.Boss then
				Analytics.record(player, "WardenDefeated")
			end
			if first then
				effects:FireClient(player, "firstclear", e.Position)
			end
			notify(
				player,
				(if first then "FIRST CLEAR · " else "")
					.. "+"
					.. (def.XP + (if first then 50 else 0))
					.. " XP · +"
					.. (def.Shards + (if first then 25 else 0))
					.. " shards"
					.. (if def.Boss then " · +" .. def.Cores .. " cores" else "")
			)
		end
	end
end
local function hitEnemy(player, s, e, action, attack)
	local p = profile(player)
	if not p or e.Dead then
		return
	end
	local def = Config.Enemies[e.Spawn.Kind]
	local damage, broke = Combat.damage(
		e,
		attack.Damage,
		player.UserId,
		os.clock(),
		action == "burst" or action == "overdrive",
		def
	)
	if damage <= 0 then
		return
	end
	if action == "strike" then
		s.Combat.Focus = math.min(100, s.Combat.Focus + 18)
	end
	if broke then
		clearWarnings(e)
		s.Combat.Focus = math.min(100, s.Combat.Focus + 20)
		effects:FireAllClients("break", e.Position)
		Analytics.record(player, "CoreBroken")
	end
	effects:FireAllClients("hit", e.Position, nil, damage)
	if e.Dead then
		defeat(e, def)
	end
end
local function combatAction(player, action, rawAim)
	local s = sessions[player]
	local p = profile(player)
	local root = validLocation(player)
	if not s or not p or not root or s.Region == "hub" then
		return
	end
	local aim = Combat.aim(rawAim)
	if not aim then
		return
	end
	local direction = Vector3.new(aim.x, 0, aim.z)
	local stats = Progression.stats(p, Config)
	local ok, attack = Combat.action(s.Combat, action, os.clock(), stats, p.Path)
	if not ok then
		notify(player, attack)
		return
	end
	if action == "dash" then
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { player.Character, enemiesFolder, warningsFolder }
		local result = workspace:Raycast(root.Position, direction * 18, params)
		local distance = if result then math.max(0, result.Distance - 2) else 18
		local start = root.Position
		local finish = start + direction * distance
		root.CFrame = CFrame.lookAt(finish, finish + direction)
		root.AssemblyLinearVelocity = Vector3.zero
		s.LastPosition = finish
		s.LastMoveAt = os.clock()
		effects:FireAllClients("dash", start, finish)
	else
		local range = if action == "strike" then stats.Range else attack.Radius
		local selected = {}
		for _, e in enemies do
			if not e.Dead and e.Spawn.Region == s.Region then
				local offset = flat(e.Position - root.Position)
				local distance = offset.Magnitude
				local facing = distance < 3 or direction:Dot(offset.Unit) > 0.15
				if
					distance <= range + Config.Enemies[e.Spawn.Kind].Scale
					and math.abs(e.Position.Y - root.Position.Y) < 18
					and (action ~= "strike" or facing)
				then
					table.insert(selected, { Enemy = e, Distance = distance })
				end
			end
		end
		table.sort(selected, function(a, b)
			return a.Distance < b.Distance
		end)
		for index, target in selected do
			if action ~= "strike" or index <= 2 then
				hitEnemy(player, s, target.Enemy, action, attack)
			end
		end
		effects:FireAllClients(action, root.Position, direction, attack.Combo)
	end
	send(player)
end
for _, object in map:GetDescendants() do
	if object:IsA("ProximityPrompt") and object.Name ~= "ChristianReading" then
		object.Triggered:Connect(function(player)
			local s = sessions[player]
			local p = profile(player)
			local root = validLocation(player)
			if
				not s
				or not p
				or not root
				or (root.Position - object.Parent.Position).Magnitude > Config.InteractionDistance
			then
				return
			end
			if not RateLimit.allow(s.Limits, "prompt", os.clock(), 0.7) then
				return
			end
			local destination = object.Parent:GetAttribute("Destination")
			if destination then
				local region = World.region(Config, destination)
				local ok, message = Progression.canEnter(p, region)
				if ok then
					returnTo(player, destination)
				else
					notify(player, message)
				end
			elseif object.Parent.Name == "ForgeStation" and s.Region == "hub" then
				appearance(player, true)
				stateEvent:FireClient(player, { OpenForge = true })
				send(player)
			end
		end)
	end
end
actionEvent.OnServerEvent:Connect(function(player, action, item)
	local s = sessions[player]
	if closing or not s or type(action) ~= "string" or #action > 24 then
		return
	end
	if not RateLimit.allow(s.Limits, "remote", os.clock(), 0.09) then
		return
	end
	local p = profile(player)
	if not p then
		return
	end
	if action == "state" then
		send(player)
		return
	end
	if action == "strike" or action == "dash" or action == "burst" or action == "overdrive" then
		combatAction(player, action, item)
		return
	end
	local root = validLocation(player)
	if
		not root
		or not Authority.forge(s.Region, (root.Position - map.hub.ForgeStation.Position).Magnitude, true)
	then
		notify(player, "Visit the relic forge in Dawn Sanctuary")
		return
	end
	if not RateLimit.allow(s.Limits, "forge", os.clock(), 0.4) then
		return
	end
	local ok, message = false, "Unknown forge action"
	if action == "upgrade" then
		ok, message = Progression.upgrade(p, item, Config)
	elseif action == "evolve" then
		ok, message = Progression.evolve(p, Config)
	elseif action == "path" then
		ok, message = Progression.path(p, item, Config)
	elseif action == "color" then
		-- Old harbor tokens remain cosmetic-only; new players use earned shards.
		if type(item) == "string" and Config.Cosmetics[item] then
			local useLegacy = not p.Owned[item] and p.Tokens >= Config.Cosmetics[item].Cost
			local currency =
				{ Tokens = if useLegacy then p.Tokens else p.Shards, Owned = p.Owned, Equipped = p.Equipped }
			ok, message = Economy.equip(currency, item, Config)
			if ok then
				if useLegacy then
					p.Tokens = currency.Tokens
				else
					p.Shards = currency.Tokens
				end
				p.Equipped = currency.Equipped
			end
		end
	elseif action == "supporter" then
		ok, message = Purchases.prompt(player)
	end
	if ok then
		appearance(player, true)
		effects:FireClient(player, "forge", root.Position)
	end
	notify(player, message)
end)
local function added(player)
	if closing or sessions[player] then
		return
	end
	sessions[player] =
		{ Region = "hub", Combat = Combat.new(), Limits = {}, LastPosition = nil, LastMoveAt = os.clock() }
	local function spawned(c)
		local root = c:WaitForChild("HumanoidRootPart", 10)
		local humanoid = c:WaitForChild("Humanoid", 10)
		if not root or not humanoid or not sessions[player] then
			return
		end
		sessions[player].Combat = Combat.new()
		returnTo(player, "hub")
		appearance(player, true)
		humanoid.Died:Connect(function()
			if sessions[player] then
				sessions[player].Combat = Combat.new()
			end
		end)
		send(player)
	end
	player.CharacterAdded:Connect(spawned)
	player:GetAttributeChangedSignal("HarborSupporter"):Connect(function()
		appearance(player, false)
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
		task.spawn(spawned, player.Character)
	end
	send(player, "Enter Verdant Reach · fight, break a charge, forge your next form")
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
for _, spawn in Config.Spawns do
	spawnEnemy(spawn)
end
RunService.Heartbeat:Connect(function(dt)
	if closing then
		return
	end
	tickAccumulator += dt
	stateAccumulator += dt
	if tickAccumulator < 0.1 then
		return
	end
	local step = math.min(tickAccumulator, 0.25)
	tickAccumulator = 0
	local now = os.clock()
	for player, s in sessions do
		local root, humanoid = validLocation(player)
		if root and s.Region == "hub" and humanoid.Health < humanoid.MaxHealth then
			humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + step * 15)
		end
	end
	for id, e in enemies do
		local def = Config.Enemies[e.Spawn.Kind]
		if e.Dead then
			if now >= e.RespawnAt then
				e.Model:Destroy()
				spawnEnemy(e.Spawn)
			end
		else
			local target, targetRoot, distance = closestTarget(e)
			if target then
				e.NoTargetSince = nil
			else
				e.NoTargetSince = e.NoTargetSince or now
				if now - e.NoTargetSince > 8 then
					e.Health = e.MaxHealth
					e.Contributors = {}
					e.State = "idle"
					e.Poise = 0
					clearWarnings(e)
				end
			end
			local event = EnemyAI.step(e, def, now, distance)
			if event == "move" and targetRoot then
				local direction = flat(targetRoot.Position - e.Position)
				if direction.Magnitude > 0.1 then
					local position = e.Position
						+ direction.Unit * math.min(def.Speed * step, direction.Magnitude)
					if flat(position - e.Home).Magnitude < 42 then
						e.Position = position
					end
					e.Model:PivotTo(CFrame.lookAt(e.Position, e.Position + direction.Unit))
				end
			elseif event == "telegraph" then
				telegraph(e, def, targetRoot)
			elseif event == "impact" then
				impact(e, def, e.Zones)
				clearWarnings(e)
				if e.Spawn.Kind == "ember_warden" and e.Phase == 2 then
					local echoZones = e.Zones
					local echoWarnings = {}
					for _, zone in echoZones do
						table.insert(echoWarnings, warningPart(zone, Color3.fromRGB(255, 84, 58)))
					end
					task.delay(0.65, function()
						if
							not closing
							and enemies[e.Spawn.Id] == e
							and not e.Dead
							and e.State ~= "exposed"
						then
							impact(e, def, echoZones)
						end
						for _, warning in echoWarnings do
							warning:Destroy()
						end
					end)
				end
			elseif not target and (e.Position - e.Home).Magnitude > 0.2 then
				e.Position = e.Position:Lerp(e.Home, math.min(1, step * 2))
				e.Model:PivotTo(CFrame.new(e.Position) * CFrame.Angles(0, math.pi, 0))
			end
			e.Model:SetAttribute("State", e.State)
			e.Model:SetAttribute("Health", e.Health)
			e.Model:SetAttribute("MaxHealth", e.MaxHealth)
			e.Model:SetAttribute("Phase", e.Phase)
			e.Label.Text = def.Name
				.. (if e.State == "windup"
					then " · BREAK CHARGE"
					elseif e.State == "exposed" then " · CORE EXPOSED"
					else "")
				.. "\n"
				.. math.ceil(e.Health)
				.. " / "
				.. e.MaxHealth
			if e.State ~= "windup" then
				e.Core.Color = if e.State == "exposed"
					then Color3.fromRGB(255, 244, 174)
					else Color3.fromRGB(unpack(World.region(Config, e.Spawn.Region).Color))
			end
		end
	end
	if stateAccumulator >= 0.3 then
		stateAccumulator = 0
		for player in sessions do
			send(player)
		end
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
