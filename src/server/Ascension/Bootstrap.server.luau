--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
if not Shared:GetAttribute("AscensionEnabled") then
	return
end
local Readiness = require(Shared.Ascension.AssetReadiness)
local Manifest = require(Shared.Ascension.AssetManifest)
local Protocol = require(Shared.Ascension.Protocol)
local Parties = require(Shared.Ascension.PartyState)
local Progression = require(Shared.Progression)
local Config = require(Shared.Config)
local Replication = require(script.Parent.ReplicationService).new(ReplicatedStorage)
local gate = Readiness.evaluate(Manifest, RunService:IsStudio())
ReplicatedStorage:SetAttribute("AscensionMode", gate.Mode)
-- This checkpoint intentionally permits only explicit Studio diagnostic sessions.
if not RunService:IsStudio() then
	ReplicatedStorage:SetAttribute(
		"AscensionMode",
		"blocked · signature checkpoint requires Studio validation"
	)
	return
end
local Physics = game:GetService("PhysicsService")
for _, group in { "AscensionPlayers", "AscensionNPC" } do
	if not Physics:IsCollisionGroupRegistered(group) then
		Physics:RegisterCollisionGroup(group)
	end
end
Physics:CollisionGroupSetCollidable("AscensionPlayers", "AscensionPlayers", false)
Physics:CollisionGroupSetCollidable("AscensionPlayers", "AscensionNPC", false)
Physics:CollisionGroupSetCollidable("AscensionNPC", "AscensionNPC", false)
Players.CharacterAutoLoads = false
local Data = require(script.Parent.Parent.DataService)
local source = ReplicatedStorage:WaitForChild("AscensionSource")
local animations = require(Shared.Ascension.AnimationPlayback).new(source.SourceClips, Manifest)
local Reward = require(script.Parent.RewardService)
local sessions = {}
local parties = Parties.new()
local notices = {}
local eventSerial = 0
local emit
local encounters
emit = function(e, event)
	eventSerial += 1
	event.version = 1
	event.encounter = e.Id
	event.timestamp = workspace:GetServerTimeNow()
	if event.ends then
		event.ends = event.timestamp + math.max(0, event.ends - os.clock())
	end
	event.seed = eventSerial
	event.material = "stone"
	Replication:combat(encounters:players(e), event)
end
encounters = require(script.Parent.EncounterService).new(source, animations, emit, function(e)
	for _, player in encounters:players(e) do
		if (e.Contribution[player.UserId] or 0) > 0 then
			task.spawn(function()
				local ok, message = Reward.grant(player, Data, Config, e.Id, "verdant_warden")
				notices[player] = if ok then "Warden defeated · " .. message else message
			end)
		else
			notices[player] = "Encounter complete · no combat contribution recorded"
		end
	end
end)
local combat = require(script.Parent.CombatService).new(Data, encounters, animations, emit)
local function spawnHero(player)
	if not player.Parent then
		return
	end
	local old = player.Character
	if old then
		animations:remove(old)
		old:Destroy()
	end
	combat:remove(player)
	combat:add(player)
	local model = source.R15CollisionProxy:Clone()
	model.Name = player.Name
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CollisionGroup = "AscensionPlayers"
		end
	end
	model:PivotTo(CFrame.new(0, 5, 52))
	model.Parent = workspace
	local profile = Data.get(player)
	if not profile then
		model:Destroy()
		return
	end
	local stats = Progression.stats(profile, Config)
	model.Humanoid.MaxHealth = stats.Health
	model.Humanoid.Health = stats.Health
	player.Character = model
	model.PrimaryPart:SetNetworkOwner(player)
	animations:play(model, "Idle")
	model.Humanoid.Died:Once(function()
		combat:remove(player)
		task.delay(3, function()
			spawnHero(player)
		end)
	end)
end
local function state(player)
	local session = sessions[player]
	local profile = Data.get(player)
	if not session or not profile then
		return
	end
	local s = combat.States[player]
	local e = encounters.ByUser[player.UserId]
	local party = parties.Groups[parties.Membership[player.UserId]]
	local invite = parties.Invites[player.UserId]
	Replication:state(player, {
		version = 2,
		session = session.Id,
		mode = gate.Mode,
		missing = #gate.Missing,
		notice = notices[player],
		stamina = s and s.Stamina or 0,
		focus = s and s.Focus or 0,
		profile = {
			Level = Progression.level(profile.XP),
			XP = profile.XP,
			Shards = profile.Shards,
			Cores = profile.Cores,
			Form = profile.Form,
			Path = profile.Path,
		},
		party = party and { leader = party.Leader, members = party.Members, ready = party.Ready } or nil,
		invite = invite and invite.Expires > os.clock() and invite.Inviter or nil,
		encounter = e and {
			id = e.Id,
			health = e.Warden.Health,
			maxHealth = e.Warden.MaxHealth,
			state = e.Warden.State,
			pattern = e.Warden.Pattern,
			phase = e.Warden.Phase,
			size = e.Size,
		} or nil,
	})
end
Replication.Events.Request.OnServerEvent:Connect(function(player, packet)
	local session = sessions[player]
	if not session then
		return
	end
	if
		type(packet) == "table"
		and packet.version == 2
		and packet.action == "state"
		and packet.session == nil
	then
		if os.clock() - (session.LastHello or -100) > 1 then
			session.LastHello = os.clock()
			state(player)
		end
		return
	end
	local request, why = Protocol.decode(session, packet, os.clock())
	if not request then
		return
	end
	local action = request.Action
	local now = os.clock()
	for _, party in parties.Groups do
		if party.Encounter then
			local active = false
			for _, encounter in encounters.State.Slots do
				if encounter.Id == party.Encounter then
					active = true
				end
			end
			if not active then
				party.Encounter = nil
				party.Ready = {}
			end
		end
	end
	local e = encounters.ByUser[player.UserId]
	if action == "enter" and e and not e.Finished then
		local c = player.Character
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if c and c.PrimaryPart and h and h.Health > 0 then
			c:PivotTo(CFrame.new(e.Center + Vector3.new(0, 5, 28)))
			notices[player] = "Rejoined current attempt · roster difficulty preserved"
		end
		state(player)
		return
	end
	if action == "state" then
		state(player)
		return
	end
	if action == "partyCreate" then
		if not e then
			Parties.create(parties, player.UserId)
		end
	elseif action == "partyInvite" then
		if request.Target and Players:GetPlayerByUserId(request.Target) then
			Parties.invite(parties, player.UserId, request.Target, now)
		end
	elseif action == "partyAccept" then
		if not e then
			Parties.accept(parties, player.UserId, now)
		end
	elseif action == "partyLeave" then
		if e then
			notices[player] = "Finish the encounter before changing party"
		else
			Parties.leave(parties, player.UserId)
		end
	elseif action == "ready" then
		Parties.ready(parties, player.UserId, request.Enabled)
	elseif action == "enter" then
		local roster = Parties.roster(parties, player.UserId)
		if roster then
			local valid = true
			for _, id in roster do
				local p = Players:GetPlayerByUserId(id)
				local c = p and p.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				if
					not p
					or not Data.get(p)
					or not c
					or not h
					or not c.PrimaryPart
					or h.Health <= 0
					or c.PrimaryPart.Position.Magnitude > 110
				then
					valid = false
				end
			end
			if valid then
				local created, reason = encounters:start(roster, now)
				local party = parties.Groups[parties.Membership[player.UserId]]
				if created and party then
					party.Encounter = created.Id
				end
				notices[player] = if created
					then "Warden encounter started · Space/jump retains control"
					else reason
			else
				notices[player] = "All members must be alive in the sanctuary"
			end
		else
			notices[player] = "Leader enters after every member readies"
		end
	elseif action == "upgrade" and not e then
		local p = Data.get(player)
		if p then
			local _, message = Progression.upgrade(p, request.Item, Config)
			notices[player] = message
		end
	elseif action == "evolve" and not e then
		local p = Data.get(player)
		if p then
			local _, message = Progression.evolve(p, Config)
			notices[player] = message
		end
	elseif action == "path" and not e then
		local p = Data.get(player)
		if p then
			local _, message = Progression.path(p, request.Item, Config)
			notices[player] = message
		end
	else
		local ok, message = combat:request(player, request, now)
		if not ok then
			Replication.Events.Gate:FireClient(
				player,
				{ kind = "rejected", sequence = request.Sequence, reason = message }
			)
			notices[player] = message
		end
	end
	state(player)
end)
local function join(player)
	if #Players:GetPlayers() > 4 then
		player:Kick("Signature validation build supports four clients")
		return
	end
	if not Data.load(player) then
		player:Kick("Profile unavailable. Progress has not been reset.")
		return
	end
	sessions[player] = Protocol.newSession(game:GetService("HttpService"):GenerateGUID(false))
	combat:add(player)
	spawnHero(player)
	local e = encounters.ByUser[player.UserId]
	if e then
		if require(Shared.Ascension.EncounterState).rejoin(e, player.UserId, os.clock()) then
			player.Character:PivotTo(CFrame.new(e.Center + Vector3.new(0, 5, 28)))
		else
			encounters.ByUser[player.UserId] = nil
		end
	end
	state(player)
end
Players.PlayerAdded:Connect(join)
for _, player in Players:GetPlayers() do
	task.spawn(join, player)
end
Players.PlayerRemoving:Connect(function(player)
	local e = encounters.ByUser[player.UserId]
	if e then
		require(Shared.Ascension.EncounterState).depart(e, player.UserId, os.clock())
	end
	Parties.leave(parties, player.UserId)
	sessions[player] = nil
	notices[player] = nil
	if player.Character then
		animations:remove(player.Character)
	end
	combat:remove(player)
	Data.save(player, true)
end)
local accumulated = 0
RunService.Heartbeat:Connect(function(dt)
	local now = os.clock()
	combat:step(now, dt)
	encounters:step(now, function(...)
		return combat:defend(...)
	end)
	accumulated += dt
	if accumulated >= 0.1 then
		accumulated = 0
		for player in sessions do
			state(player)
		end
	end
end)
task.spawn(function()
	while task.wait(30) do
		for player in sessions do
			Data.save(player, false)
		end
	end
end)
game:BindToClose(function()
	local pending = 0
	for player in sessions do
		pending += 1
		task.spawn(function()
			Data.save(player, true)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 25
	while pending > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)
