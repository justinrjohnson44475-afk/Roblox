--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local T = require(Shared.Ascension.Traversal)
local Movement = {}
function Movement.new(world, feedback)
	local self = { World = world, Dashes = {}, Walls = {}, Air = {} }
	local function params(player)
		local p = RaycastParams.new()
		p.CollisionGroup = "AscensionPlayers"
		p.FilterType = Enum.RaycastFilterType.Exclude
		p.FilterDescendantsInstances = { player.Character }
		p.RespectCanCollide = true
		return p
	end
	local function emit(player, action, extra)
		if feedback then
			feedback(player, action, extra or {})
		end
	end
	local function force(root, name)
		local a = Instance.new("Attachment")
		a.Name = name .. "Attachment"
		a.Parent = root
		local v = Instance.new("LinearVelocity")
		v.Name = name
		v.Attachment0 = a
		v.RelativeTo = Enum.ActuatorRelativeTo.World
		v.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
		v.ForceLimitsEnabled = true
		v.MaxForce = root.AssemblyMass * 6000
		v.VectorVelocity = Vector3.zero
		v.Parent = root
		root:SetNetworkOwner(nil)
		return a, v
	end
	function self:stop(player, kind)
		local collection = if kind == "dash" then self.Dashes else self.Walls
		local move = collection[player]
		if not move then
			return
		end
		move.Force:Destroy()
		move.Attachment:Destroy()
		collection[player] = nil
		if move.Root.Parent then
			local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if h then
				h.AutoRotate = true
			end
			local velocity = move.Root.AssemblyLinearVelocity
			move.Root.AssemblyLinearVelocity = Vector3.new(0, math.clamp(velocity.Y, -15, 15), 0)
			pcall(function()
				move.Root:SetNetworkOwnershipAuto()
			end)
		end
		if kind == "wall" then
			self:airState(player).WallUntil = 0
			emit(player, "wallend")
		end
	end
	function self:stopDash(player)
		self:stop(player, "dash")
	end
	function self:airState(player)
		if not self.Air[player] then
			self.Air[player] = T.new()
		end
		return self.Air[player]
	end
	function self:observe(player, root, humanoid, now)
		local hit = world:Raycast(
			root.Position,
			Vector3.new(0, -(humanoid.HipHeight + root.Size.Y * 0.5 + 0.22), 0),
			params(player)
		)
		local grounded = hit ~= nil and hit.Normal.Y > 0.65 and root.AssemblyLinearVelocity.Y <= 3
		T.observe(self:airState(player), grounded, now)
		return grounded
	end
	function self:canDash(player, root, aim)
		return world:Blockcast(root.CFrame, Vector3.new(1.8, 2.6, 1.4), aim * 2, params(player)) == nil
	end
	function self:dash(player, root, aim, now, definition)
		-- Preflight before resource spend or attachment creation. Keep the collision hull intact.
		local hit = world:Blockcast(root.CFrame, Vector3.new(1.8, 2.6, 1.4), aim * 2, params(player))
		if hit then
			return false
		end
		self:stop(player, "wall")
		self:stopDash(player)
		local a, v = force(root, "AscensionPhaseDash")
		player.Character.Humanoid.AutoRotate = false
		self.Dashes[player] = {
			Root = root,
			Start = root.Position,
			At = now,
			Ends = now + definition.Duration,
			Direction = aim,
			Force = v,
			Attachment = a,
			Distance = definition.Distance,
			Duration = definition.Duration,
		}
		return true
	end
	function self:airJump(player, root, humanoid, now)
		self:observe(player, root, humanoid, now)
		if not T.airJump(self:airState(player), now) then
			return false, "Air jump already used or not airborne"
		end
		local wall = self.Walls[player]
		local away = wall and wall.Normal * 16 or Vector3.zero
		self:stop(player, "wall")
		self:stopDash(player)
		root:SetNetworkOwner(nil)
		task.delay(0.12, function()
			if root.Parent and not self.Dashes[player] and not self.Walls[player] then
				root:SetNetworkOwnershipAuto()
			end
		end)
		humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		local v = root.AssemblyLinearVelocity
		root.AssemblyLinearVelocity = Vector3.new(v.X, T.DoubleJumpVelocity, v.Z) + away
		return true
	end
	function self:wall(player, root, humanoid, aim, now, stamina)
		self:observe(player, root, humanoid, now)
		if self.Dashes[player] or self.Walls[player] then
			return false
		end
		local hit
		for _, direction in { root.CFrame.RightVector, -root.CFrame.RightVector } do
			local candidate = world:Raycast(root.Position, direction * 3.4, params(player))
			if
				candidate
				and math.abs(candidate.Normal.Y) < 0.2
				and candidate.Instance:IsA("BasePart")
				and candidate.Instance.Anchored
			then
				hit = candidate
				break
			end
		end
		local tangent = hit and (aim - hit.Normal * aim:Dot(hit.Normal)) or Vector3.zero
		if tangent.Magnitude < 0.35 then
			return false
		end
		if not T.wall(self:airState(player), now, hit ~= nil, stamina) then
			return false
		end
		local a, v = force(root, "AscensionWallRun")
		humanoid.AutoRotate = false
		self.Walls[player] = {
			Root = root,
			At = now,
			Ends = now + T.WallDuration,
			Normal = hit.Normal,
			Direction = tangent.Unit,
			Force = v,
			Attachment = a,
		}
		emit(
			player,
			"wallrun",
			{ clip = T.clip("wall", 0, hit.Normal:Dot(root.CFrame.RightVector)), duration = T.WallDuration }
		)
		return true
	end
	function self:step(now, dt)
		for player, d in self.Dashes do
			local speed = T.dashSpeed((now - d.At) / d.Duration, d.Distance, d.Duration)
			local direction = d.Direction * math.max(0.2, speed * math.min(dt, 0.05) + 0.6)
			if
				not d.Root.Parent
				or now >= d.Ends
				or (d.Root.Position - d.Start).Magnitude >= d.Distance
				or world:Blockcast(d.Root.CFrame, Vector3.new(1.8, 2.6, 1.4), direction, params(player))
			then
				self:stopDash(player)
			else
				-- Brief vertical hold prevents the hanging/falling silhouette of the earlier horizontal tether.
				d.Force.VectorVelocity = d.Direction * speed
			end
		end
		for player, w in self.Walls do
			local state = self:airState(player)
			local contact = w.Root.Parent and world:Raycast(w.Root.Position, -w.Normal * 3.8, params(player))
			if not contact or contact.Normal:Dot(w.Normal) < 0.85 or now >= w.Ends or state.Grounded then
				self:stop(player, "wall")
			else
				local u = (now - w.At) / T.WallDuration
				w.Force.VectorVelocity = w.Direction * T.WallSpeed
					+ Vector3.new(0, 5 - 12 * u, 0)
					- w.Normal * 2
				local step = T.wallStep(state, now)
				if step then
					emit(player, "wallstep", { step = step, normal = w.Normal })
				end
			end
		end
	end
	function self:locomotion(player, humanoid, state, dt)
		local desired = if state.Guard
			then 8
			elseif state.Attack then 10
			elseif state.Sprint then T.SprintSpeed
			else T.RunSpeed
		humanoid.WalkSpeed += (desired - humanoid.WalkSpeed) * (1 - math.exp(-math.min(dt, 0.1) * 18))
	end
	function self:remove(player)
		self:stopDash(player)
		self:stop(player, "wall")
		self.Air[player] = nil
	end
	return self
end
return Movement
