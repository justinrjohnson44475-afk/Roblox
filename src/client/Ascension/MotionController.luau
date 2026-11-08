--!strict
local Run = game:GetService("RunService")
local Players = game:GetService("Players")
local Shared = game:GetService("ReplicatedStorage").Shared
local Def = require(Shared.Ascension.AttackDefinitions)
local T = require(Shared.Ascension.Traversal)
local Motion = {}
function Motion.new(player, animations, presentation, send)
	local self = {
		Predicted = {},
		BusyUntil = 0,
		Queue = nil,
		Combo = 0,
		ComboAt = -100,
		Sprint = false,
		Wall = false,
		WallUsed = false,
		AirUsed = false,
		LastWallTry = -100,
		Locomotion = nil,
		Lean = CFrame.identity,
		AppliedLean = CFrame.identity,
		Model = nil,
		Grounded = true,
		FallSpeed = 0,
	}
	local function now()
		return workspace:GetServerTimeNow()
	end
	function self:play(name, fade)
		if not self.Model then
			return nil
		end
		return animations:play(self.Model, name, fade)
	end
	function self:attack(action)
		local time = now()
		if time < self.BusyUntil then
			self.Queue = { Action = action, Expires = time + 0.18 }
			return
		end
		local clip = ({ light = "Light1", heavy = "Heavy", burst = "Coreburst", overdrive = "Overdrive" })[action]
		if not clip or not self.Model then
			return
		end
		if action == "light" then
			self.Combo = if time - self.ComboAt < 1.2 then self.Combo % 3 + 1 else 1
			self.ComboAt = time
			clip = "Light" .. self.Combo
		end
		local sequence = send(action)
		if not sequence then
			return
		end
		self.BusyUntil = time + Def[clip].Duration
		self.Queue = nil
		local track = self:play(clip, 0.035)
		self.Predicted[sequence] =
			{ Track = track, Name = clip, At = time, Expires = time + 0.8, Attack = true }
	end
	function self:dash()
		local c = self.Model
		local root = c and c.PrimaryPart
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if not root or not h then
			return
		end
		local aim = if h.MoveDirection.Magnitude > 0.1 then h.MoveDirection else root.CFrame.LookVector
		aim = Vector3.new(aim.X, 0, aim.Z).Unit
		local sequence = send("dash", { aim = { x = aim.X, y = 0, z = aim.Z } })
		if not sequence then
			return
		end
		local clip = T.clip("dash", root.CFrame.LookVector:Dot(aim), root.CFrame.RightVector:Dot(aim))
		self.Predicted[sequence] =
			{ Track = self:play(clip, 0.025), Name = clip, At = now(), Expires = now() + 0.55 }
		presentation:phase(c, now())
		self.BusyUntil = math.max(self.BusyUntil, now() + Def.Dash.Duration)
	end
	function self:jump()
		local c = self.Model
		local h = c and c:FindFirstChildOfClass("Humanoid")
		if not h or h.Health <= 0 or h.FloorMaterial ~= Enum.Material.Air or self.AirUsed then
			return false
		end
		local sequence = send("airJump")
		if not sequence then
			return false
		end
		self.AirUsed = true
		self.Predicted[sequence] = {
			Track = self:play("DoubleJump", 0.035),
			Name = "DoubleJump",
			At = now(),
			Expires = now() + 0.7,
			Air = true,
		}
		return true
	end
	function self:reject(event)
		local p = self.Predicted[event.sequence]
		if p then
			if p.Track then
				p.Track:Stop(0.08)
			end
			if p.Attack then
				self.BusyUntil = now()
				self.Queue = nil
			end
			if p.Air then
				self.AirUsed = false
			end
			self.Predicted[event.sequence] = nil
		end
	end
	function self:event(event)
		if event.target == player.UserId then
			if event.result == "parry" then
				self:play("Parry", 0.03)
			elseif event.result == "guardbreak" then
				self:play("GuardBreak", 0.04)
			elseif event.result == "hit" then
				self:play("Hurt", 0.04)
			end
		end
		if event.actor ~= player.UserId then
			return
		end
		local p = event.sequence and self.Predicted[event.sequence]
		if event.result == "attack" then
			-- Keep accepted prediction playing: stopping it here produced a visible confirmation hitch.
			if not p or p.Name ~= event.action then
				self:play(event.action, 0.04)
			end
			if p and p.Track and now() - event.timestamp > 0.07 then
				p.Track:AdjustSpeed(0.92)
				p.RestoreAt = now() + 0.15
			end
			self.BusyUntil = event.ends or self.BusyUntil
		elseif event.result == "dash" or event.result == "airJump" then
			if not p then
				self:play(event.clip, 0.035)
				if event.result == "dash" then
					presentation:phase(self.Model, now())
				end
			end
		elseif event.result == "wallrun" then
			self.Wall = true
			self.WallUsed = true
			self:play(event.clip, 0.07)
		elseif event.result == "wallend" then
			self.Wall = false
			local channel = animations.Channels[self.Model]
			local track = channel and channel.Mobility
			if track and track.Name:find("WallRun") then
				animations:stop(self.Model, "Mobility", 0.08)
			end
		elseif event.target == player.UserId then
			if event.result == "parry" then
				self:play("Parry", 0.03)
			elseif event.result == "guardbreak" then
				self:play("GuardBreak", 0.04)
			elseif event.result == "hit" then
				self:play("Hurt", 0.04)
			end
		end
		if p then
			p.Confirmed = true
		end
	end
	function self:character(model)
		self.Model = model
		self.Predicted = {}
		self.Queue = nil
		self.BusyUntil = 0
		self.Combo = 0
		self.ComboAt = -100
		self.Locomotion = nil
		self.Grounded = true
		self.AirUsed = false
		self.WallUsed = false
		self.Wall = false
		self.FallSpeed = 0
		self.Lean = CFrame.identity
		self.AppliedLean = CFrame.identity
		self.Joint = model:FindFirstChild("LowerTorsoJoint", true)
	end
	function self:step(dt, state)
		local time = now()
		local c = self.Model
		local h = c and c:FindFirstChildOfClass("Humanoid")
		local root = c and c.PrimaryPart
		if not c or not c.Parent or not h or not root or h.Health <= 0 then
			return
		end
		for sequence, p in self.Predicted do
			if p.RestoreAt and time >= p.RestoreAt then
				if p.Track then
					p.Track:AdjustSpeed(1)
				end
				p.RestoreAt = nil
			end
			if time >= p.Expires then
				if not p.Confirmed and p.Track then
					p.Track:Stop(0.10)
				end
				self.Predicted[sequence] = nil
			end
		end
		if self.Queue then
			if time > self.Queue.Expires then
				self.Queue = nil
			elseif time >= self.BusyUntil then
				local action = self.Queue.Action
				self.Queue = nil
				self:attack(action)
			end
		end
		local grounded = h.FloorMaterial ~= Enum.Material.Air
		if grounded then
			if not self.Grounded then
				animations:stop(c, "Mobility", 0.07)
				self.Wall = false
				if time >= self.BusyUntil then
					self:play(if self.FallSpeed < -50 then "HeavyLand" else "Land", 0.05)
				end
			end
			self.AirUsed = false
			self.WallUsed = false
			self.FallSpeed = 0
		else
			self.FallSpeed = math.min(self.FallSpeed, root.AssemblyLinearVelocity.Y)
		end
		self.Grounded = grounded
		if
			self.Sprint
			and not grounded
			and not self.WallUsed
			and time - self.LastWallTry > 0.30
			and h.MoveDirection.Magnitude > 0.2
		then
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Exclude
			params.FilterDescendantsInstances = { c }
			params.RespectCanCollide = true
			params.CollisionGroup = "AscensionPlayers"
			for _, dir in { root.CFrame.RightVector, -root.CFrame.RightVector } do
				local hit = workspace:Raycast(root.Position, dir * 3.4, params)
				if hit and math.abs(hit.Normal.Y) < 0.2 then
					self.LastWallTry = time
					send("wallrun", { aim = { x = h.MoveDirection.X, y = 0, z = h.MoveDirection.Z } })
					break
				end
			end
		end
		local localMove = root.CFrame:VectorToObjectSpace(h.MoveDirection)
		local nextClip
		if not grounded then
			nextClip = if root.AssemblyLinearVelocity.Y > 3 then "Jump" else "Fall"
		elseif h.MoveDirection.Magnitude < 0.1 then
			nextClip = if state and state.encounter then "CombatIdle" else "Idle"
		elseif state and state.guard then
			nextClip = if localMove.X < -0.3 then "StrafeLeft" else "StrafeRight"
		else
			nextClip = if self.Sprint and h.WalkSpeed > 20
				then "Sprint"
				elseif h.WalkSpeed < 10 then "Walk"
				else "Run"
		end
		if nextClip ~= self.Locomotion then
			self.Locomotion = nextClip
			self:play(nextClip, 0.14)
		end
		local track = animations.Tracks[c] and animations.Tracks[c][nextClip]
		if track and (nextClip == "Run" or nextClip == "Sprint" or nextClip == "Walk") then
			local nominal = if nextClip == "Sprint"
				then T.SprintSpeed
				elseif nextClip == "Run" then T.RunSpeed
				else 8
			track:AdjustSpeed(math.clamp(root.AssemblyLinearVelocity.Magnitude / nominal, 0.65, 1.35))
		end
		local lean = if grounded and time >= self.BusyUntil
			then CFrame.Angles(0, 0, -localMove.X * 0.09)
			else CFrame.identity
		self.Lean = self.Lean:Lerp(lean, 1 - math.exp(-dt * 14))
	end
	Run.PreAnimation:Connect(function()
		if self.Joint and self.Joint.Parent then
			self.Joint.Transform *= self.AppliedLean:Inverse()
		end
		self.AppliedLean = CFrame.identity
	end)
	Run.PreSimulation:Connect(function()
		if self.Joint and self.Joint.Parent then
			self.Joint.Transform *= self.Lean
			self.AppliedLean = self.Lean
		end
	end)
	return self
end
return Motion
