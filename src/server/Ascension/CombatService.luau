--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Definitions = require(Shared.Ascension.AttackDefinitions)
local Timeline = require(Shared.Ascension.CombatTimeline)
local Progression = require(Shared.Progression)
local Config = require(Shared.Config)
local Hitbox = require(script.Parent.HitboxService)
local Movement = require(script.Parent.MovementService)
local Membership = require(Shared.Ascension.EncounterState)
local BuildAdapter = require(Shared.Ascension.BuildAdapter)
local Combat = {}
function Combat.new(data, encounters, animations, emit)
	local self = { States = {}, Movement = Movement.new(workspace), Positions = {} }
	function self:add(player)
		self.States[player] = Timeline.new()
		self.Positions[player] = nil
	end
	function self:remove(player)
		self.Movement:remove(player)
		self.States[player] = nil
		self.Positions[player] = nil
	end
	function self:request(player, request, now)
		local s = self.States[player]
		local c = player.Character
		local root = c and c.PrimaryPart
		local hum = c and c:FindFirstChildOfClass("Humanoid")
		local profile = data.get(player)
		if not s or not root or not hum or hum.Health <= 0 or not profile then
			return false, "unavailable"
		end
		local stats = Progression.stats(profile, Config)
		local aim = request.Aim and Vector3.new(request.Aim.x, 0, request.Aim.z) or root.CFrame.LookVector
		local action = request.Action
		if action == "guard" then
			return Timeline.guard(s, request.Enabled == true, now)
		end
		if action == "sprint" then
			s.Sprint = request.Enabled == true
			return true
		end
		if action == "dash" then
			if not Timeline.dash(s, now, stats, Definitions) then
				return false, "dash unavailable"
			end
			self.Movement:dash(player, root, aim, now, Definitions.Dash)
			animations:play(c, "DashForward")
			return true
		end
		local e = encounters.ByUser[player.UserId]
		if not e or not Membership.contains(e, player.UserId) or e.Finished then
			return false, "enter the encounter first"
		end
		-- Client root movement cannot carry accepted hits across arena space. Reject implausible steps.
		local last = self.Positions[player]
		if
			(root.Position - e.Center).Magnitude > 105
			or (last and (root.Position - last.Position).Magnitude > math.max(5, (now - last.At) * 100))
		then
			return false, "movement"
		end
		if aim:Dot(root.CFrame.LookVector) < -0.15 then
			return false, "facing"
		end
		local a, reason = Timeline.begin(s, action, now, stats, Definitions)
		if not a then
			return false, reason
		end
		a.Build = BuildAdapter.accept(s, Definitions[a.Definition], stats, profile.Path, now)
		a.Encounter = e.Id
		a.Origin = root.CFrame
		a.RootPosition = root.Position
		-- Bounded aim is intent only; enforce facing before accepting canonical sweep.
		animations:play(c, Definitions[a.Definition].Animation)
		emit(e, {
			result = "attack",
			attack = a.Id,
			action = Definitions[a.Definition].Animation,
			actor = player.UserId,
			sequence = request.Sequence,
			position = root.Position,
		})
		return true
	end
	function self:defend(player, damage, now, facing, core)
		local s = self.States[player]
		if not s then
			return damage, "hit"
		end
		return Timeline.defend(s, damage, now, facing, core, Definitions)
	end
	function self:step(now, dt)
		self.Movement:step(now, dt)
		for player, s in self.States do
			local c = player.Character
			local root = c and c.PrimaryPart
			local hum = c and c:FindFirstChildOfClass("Humanoid")
			local profile = data.get(player)
			if not root or not hum or hum.Health <= 0 or not profile then
				s.Attack = nil
				s.Guard = false
				self.Movement:remove(player)
				continue
			end
			local e = encounters.ByUser[player.UserId]
			local last = self.Positions[player]
			local plausible = not last
				or (root.Position - last.Position).Magnitude <= math.max(5, (now - last.At) * 100)
			self.Positions[player] = { Position = root.Position, At = now }
			Timeline.regenerate(s, dt, now)
			self.Movement:locomotion(player, hum, s)
			local sweep, finished = Timeline.advance(s, now, Definitions)
			if
				sweep
				and plausible
				and e
				and Membership.contains(e, player.UserId)
				and sweep.Attack.Encounter == e.Id
				and not e.Finished
				and (root.Position - sweep.Attack.RootPosition).Magnitude < 8
			then
				local a, def = sweep.Attack, sweep.Definition
				if
					not a.Hits[e.Id]
					and Hitbox.canHit(
						workspace,
						c,
						a.Origin,
						e.Actor,
						def,
						sweep.From,
						sweep.To,
						a.Build.ReachScale
					)
					and Timeline.hit(a, e.Id)
				then
					local stats = Progression.stats(profile, Config)
					local amount = encounters:damage(
						player,
						e,
						a.Build.Damage,
						a.Definition == "Heavy" or a.Definition == "Coreburst" or a.Definition == "Overdrive",
						now
					)
					if amount then
						s.Focus = math.min(100, s.Focus + 10)
						emit(e, {
							attack = a.Id,
							result = if e.Warden.State == "exposed" then "exposed" else def.Impact,
							position = e.Actor.PrimaryPart.Position,
							actor = player.UserId,
							damage = amount,
						})
					end
				end
			end
			if finished and finished.HitCount == 0 and e then
				emit(
					e,
					{ attack = finished.Id, result = "miss", position = root.Position, actor = player.UserId }
				)
			end
		end
	end
	return self
end
return Combat
