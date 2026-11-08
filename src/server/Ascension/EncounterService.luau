--!strict
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local State = require(Shared.Ascension.EncounterState)
local Warden = require(Shared.Ascension.WardenState)
local Navigation = require(script.Parent.NavigationService)
local Encounters = {}
function Encounters.new(source, animations, emit, onWin)
	local self = {
		State = State.new(),
		Navigation = Navigation.new(),
		ByUser = {},
		Actors = {},
		Animations = animations,
	}
	local prefix = game:GetService("HttpService"):GenerateGUID(false)
	function self:players(e)
		local list = {}
		for _, user in e.Roster do
			local p = Players:GetPlayerByUserId(user)
			if p then
				table.insert(list, p)
			end
		end
		return list
	end
	function self:start(roster, now)
		for _, id in roster do
			if self.ByUser[id] then
				return nil, "Already in an encounter"
			end
		end
		local e = State.allocate(self.State, roster, now)
		if not e then
			return nil, "No encounter space available"
		end
		e.Id = prefix .. ":" .. e.Id
		e.Center = Vector3.new(e.Slot * 512, 0, 0)
		local arena = workspace.SignatureArena:Clone()
		arena.Name = e.Id
		arena:PivotTo(arena:GetPivot() + e.Center)
		arena.Parent = workspace
		e.Arena = arena
		local actor = source.R15CollisionProxy:Clone()
		actor.Name = "Verdant Warden · collision proxy"
		actor:ScaleTo(1.7)
		actor:PivotTo(CFrame.new(e.Center + Vector3.new(0, 6, -22)))
		actor.Parent = workspace
		actor.Humanoid.MaxHealth = 600 * e.Scale
		actor.Humanoid.Health = actor.Humanoid.MaxHealth
		actor.Humanoid.WalkSpeed = 10
		actor.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		actor.PrimaryPart:SetNetworkOwner(nil)
		e.Actor = actor
		e.Warden = Warden.new(actor.Humanoid.Health, now)
		e.Contribution = {}
		e.Aim = Vector3.zero
		e.LastProgress = now
		e.LastPosition = actor.PrimaryPart.Position
		self.Actors[actor] = e
		for _, id in roster do
			self.ByUser[id] = e
			local p = Players:GetPlayerByUserId(id)
			if p and p.Character then
				p.Character:PivotTo(
					CFrame.new(e.Center + Vector3.new((table.find(roster, id) - 2.5) * 5, 5, 28))
				)
			end
		end
		animations:play(actor, "WardenIdle")
		return e
	end
	function self:remove(e)
		self.Navigation:remove(e.Actor)
		animations:remove(e.Actor)
		self.Actors[e.Actor] = nil
		e.Actor:Destroy()
		e.Arena:Destroy()
		for _, id in e.Roster do
			if self.ByUser[id] == e then
				self.ByUser[id] = nil
			end
			local p = Players:GetPlayerByUserId(id)
			if p and p.Character then
				p.Character:PivotTo(CFrame.new(0, 5, 52))
			end
		end
		State.release(self.State, e)
	end
	function self:damage(player, e, amount, breaker, now)
		if not State.contains(e, player.UserId) or e.Warden.Health <= 0 then
			return nil
		end
		local dealt, broken = Warden.damage(e.Warden, amount, breaker, now)
		e.Contribution[player.UserId] = (e.Contribution[player.UserId] or 0) + dealt
		e.Actor.Humanoid.Health = e.Warden.Health
		if broken then
			animations:play(e.Actor, "WardenExposed")
			emit(e, { result = "corebreak", position = e.Actor.PrimaryPart.Position })
		end
		return dealt
	end
	function self:step(now, defend)
		for _, e in self.State.Slots do
			if e.State ~= "active" then
				continue
			end
			if e.Finished then
				if now >= e.Finished + 6 then
					self:remove(e)
				end
				continue
			end
			local root = e.Actor.PrimaryPart
			local nearest, dist = nil, math.huge
			for _, p in self:players(e) do
				local c = p.Character
				local h = c and c:FindFirstChildOfClass("Humanoid")
				local r = c and c.PrimaryPart
				if State.contains(e, p.UserId) and r and h and h.Health > 0 then
					local d = (r.Position - root.Position).Magnitude
					if d < dist then
						nearest = p
						dist = d
					end
				end
			end
			if e.Warden.Health <= 0 then
				e.Finished = now
				onWin(e)
				emit(e, { result = "victory", position = root.Position })
				continue
			end
			if not nearest then
				e.EmptyAt = e.EmptyAt or now
				if now - e.EmptyAt > 60 then
					self:remove(e)
				end
				continue
			end
			e.EmptyAt = nil
			if (root.Position - e.LastPosition).Magnitude > 2 then
				e.LastProgress = now
				e.LastPosition = root.Position
			end
			if now - e.LastProgress > 10 or (root.Position - e.Center).Magnitude > 110 then
				-- Explicit reset after failed navigation; stable collision and roster scaling remain fixed.
				e.Actor:PivotTo(CFrame.new(e.Center + Vector3.new(0, 6, -22)))
				e.LastProgress = now
				e.LastPosition = root.Position
				e.Warden.State = "recovery"
				e.Warden.Until = now + 1
				emit(e, { result = "reposition", position = root.Position })
			end
			local action, pattern = Warden.tick(e.Warden, now, dist)
			if action == "navigate" then
				self.Navigation:move(e.Actor, nearest.Character.PrimaryPart.Position, now)
				if e.Locomotion ~= "walk" then
					animations:play(e.Actor, "WardenWalk")
					e.Locomotion = "walk"
				end
			elseif action == "telegraph" then
				e.Locomotion = nil
				e.Actor.Humanoid:MoveTo(root.Position)
				e.Aim = nearest.Character.PrimaryPart.Position
				local horizontal = Vector3.new(e.Aim.X, root.Position.Y, e.Aim.Z)
				if (horizontal - root.Position).Magnitude > 0.1 then
					root.CFrame = CFrame.lookAt(root.Position, horizontal)
				end
				animations:play(e.Actor, if pattern == "lance" then "WardenLance" else "WardenSlam")
				emit(e, { result = "telegraph", pattern = pattern, position = e.Aim, ends = e.Warden.Until })
			elseif action == "impact" then
				for _, p in self:players(e) do
					local c = p.Character
					local r = c and c.PrimaryPart
					local h = c and c:FindFirstChildOfClass("Humanoid")
					if r and h and h.Health > 0 and State.contains(e, p.UserId) then
						local delta = r.Position - root.Position
						local inRange = if pattern == "core"
							then (r.Position - e.Aim).Magnitude < 13
							elseif pattern == "lance" then (r.Position - e.Aim).Magnitude < 6
							else delta.Magnitude < 11 and delta.Unit:Dot(root.CFrame.LookVector) > 0.2
						if inRange then
							local params = RaycastParams.new()
							params.FilterType = Enum.RaycastFilterType.Exclude
							params.FilterDescendantsInstances = { e.Actor }
							params.RespectCanCollide = true
							local obstruction = workspace:Raycast(root.Position, delta, params)
							if not obstruction or obstruction.Instance:IsDescendantOf(c) then
								local facing = r.CFrame.LookVector:Dot(-delta.Unit)
								local damage, result = defend(
									p,
									if pattern == "core" then 38 else 22,
									now,
									facing,
									pattern == "core"
								)
								h:TakeDamage(damage)
								if result == "parry" then
									Warden.parry(e.Warden, now)
									e.Contribution[p.UserId] = (e.Contribution[p.UserId] or 0) + 15
								end
								emit(e, { result = result, position = r.Position, target = p.UserId })
							end
						end
					end
				end
				emit(e, {
					result = "ground",
					pattern = pattern,
					position = if pattern == "melee" then root.Position else e.Aim,
				})
			elseif action == "recover" then
				animations:play(e.Actor, "WardenIdle")
			end
		end
	end
	return self
end
return Encounters
