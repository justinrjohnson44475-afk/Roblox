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
function Combat.new(data, encounters, animations, emit, movementFeedback)
	local self = { States = {}, Movement = Movement.new(workspace, movementFeedback), Positions = {} }
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
		if s.PreviewAbilities then
			stats.Level = math.max(5, stats.Level)
		end
		local action = request.Action
		if action == "heavyCharge" then
			if self.Movement.Dashes[player] or self.Movement.Walls[player] then
				return false, "Finish traversal before charging"
			end
			return Timeline.charge(s, request.Enabled == true, now),
				"Heavy unavailable: finish current action or recover stamina"
		end
		self.Movement:observe(player, root, hum, now)
		if action == "airJump" or action == "wallrun" then
			if s.Attack or s.Guard or now < s.LockedUntil then
				return false, "committed"
			end
			if action == "airJump" then
				local ok, reason = self.Movement:airJump(player, root, hum, now)
				if ok and movementFeedback then
					movementFeedback(player, "airJump", { clip = "DoubleJump", sequence = request.Sequence })
				end
				return ok, reason
			end
			if not s.Sprint then
				return false, "Hold sprint to wall run"
			end
			local ok = self.Movement:wall(player, root, hum, aim, now, s.Stamina)
			if ok then
				s.Stamina -= 12
				s.LastSpend = now
			end
			return ok, "No runnable wall or wall run already used"
		end
		if action == "guard" then
			return Timeline.guard(s, request.Enabled == true, now)
		end
		if action == "sprint" then
			s.Sprint = request.Enabled == true
			if not s.Sprint then
				self.Movement:stop(player, "wall")
			end
			return true
		end
		if action == "dash" then
			if not self.Movement:canDash(player, root, aim) then
				return false, "Wall blocks dash"
			end
			if not Timeline.dash(s, now, stats, Definitions) then
				return false, "dash unavailable"
			end
			self.Movement:dash(player, root, aim, now, Definitions.Dash)
			if movementFeedback then
				movementFeedback(player, "dash", {
					clip = require(Shared.Ascension.Traversal).clip(
						"dash",
						root.CFrame.LookVector:Dot(aim),
						root.CFrame.RightVector:Dot(aim)
					),
					duration = Definitions.Dash.Duration,
					sequence = request.Sequence,
				})
			end
			return true
		end
		if self.Movement.Dashes[player] or self.Movement.Walls[player] then
			return false, "Finish traversal before attacking"
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
		a.Build.Damage = math.floor(
			a.Build.Damage
				* a.ChargeScale
				* (if now < s.OverdriveUntil and (action == "light" or action == "heavy") then 1.25 else 1)
		)
		a.Build.Radius = if action == "overdrive" then 23 else stats.BurstRadius
		a.Encounter = e.Id
		a.Origin = root.CFrame
		a.RootPosition = root.Position
		-- Bounded aim is intent only; enforce facing before accepting canonical sweep.
		-- Owning client predicts animation on the server-created Animator; markers never authorize damage.
		emit(e, {
			result = "attack",
			ends = a.EndAt,
			attack = a.Id,
			action = Definitions[a.Definition].Animation,
			offset = if action == "heavy" then Definitions.Heavy.Windup else 0,
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
			self.Movement:observe(player, root, hum, now)
			Timeline.regenerate(s, dt, now)
			self.Movement:locomotion(player, hum, s, dt)
			local sweep, finished = Timeline.advance(s, now, Definitions)
			if
				sweep
				and e
				and Membership.contains(e, player.UserId)
				and sweep.Attack.Encounter == e.Id
				and not e.Finished
				and not sweep.Attack.CueEmitted
				and (sweep.Attack.Definition == "Coreburst" or sweep.Attack.Definition == "Overdrive")
			then
				sweep.Attack.CueEmitted = true
				if sweep.Attack.Definition == "Overdrive" then
					s.OverdriveUntil = now + 8
				end
				emit(e, {
					result = if sweep.Attack.Definition == "Overdrive" then "overdrive" else "coreburst",
					actor = player.UserId,
					attack = sweep.Attack.Id,
					position = root.Position,
					radius = sweep.Attack.Build.Radius,
					duration = 8,
				})
			end
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
						a.Build.ReachScale,
						a.Build.Radius
					)
					and Timeline.hit(a, e.Id)
				then
					local stats = Progression.stats(profile, Config)
					local amount = encounters:damage(
						player,
						e,
						a.Build.Damage,
						if a.Definition == "Coreburst"
							then "coreburst"
							else a.Definition == "Heavy" or a.Definition == "Overdrive",
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
