--!strict
local Movement = {}
function Movement.new(world)
	local self = { World = world, Dashes = {}, Samples = {} }
	function self:stopDash(player)
		local d = self.Dashes[player]
		if not d then
			return
		end
		d.Force:Destroy()
		d.Attachment:Destroy()
		if d.Root.Parent then
			local velocity = d.Root.AssemblyLinearVelocity
			d.Root.AssemblyLinearVelocity = Vector3.new(0, velocity.Y, 0)
			pcall(function()
				d.Root:SetNetworkOwnershipAuto()
			end)
		end
		self.Dashes[player] = nil
	end
	function self:dash(player, root, aim, now, definition)
		self:stopDash(player)
		local attachment = Instance.new("Attachment")
		attachment.Name = "AscensionDashAttachment"
		attachment.Parent = root
		local force = Instance.new("LinearVelocity")
		force.Name = "AscensionDash"
		force.Attachment0 = attachment
		force.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
		force.PrimaryTangentAxis = Vector3.xAxis
		force.SecondaryTangentAxis = Vector3.zAxis
		force.RelativeTo = Enum.ActuatorRelativeTo.World
		force.ForceLimitsEnabled = false
		force.PlaneVelocity = Vector2.new(aim.X, aim.Z) * (definition.Distance / definition.Duration)
		force.Parent = root
		pcall(function()
			root:SetNetworkOwner(nil)
		end)
		self.Dashes[player] = {
			Root = root,
			Start = root.Position,
			At = now,
			Ends = now + definition.Duration,
			Direction = aim,
			Force = force,
			Attachment = attachment,
			Distance = definition.Distance,
		}
	end
	function self:step(now, dt)
		for player, d in self.Dashes do
			if not d.Root.Parent or now >= d.Ends or (d.Root.Position - d.Start).Magnitude >= d.Distance then
				self:stopDash(player)
			else
				local params = RaycastParams.new()
				params.FilterType = Enum.RaycastFilterType.Exclude
				params.FilterDescendantsInstances = { player.Character }
				params.RespectCanCollide = true
				local hit = self.World:Blockcast(
					d.Root.CFrame,
					Vector3.new(2, 3.5, 2),
					d.Direction * math.max(1, 82 * math.min(dt, 0.05) + 0.5),
					params
				)
				if hit then
					self:stopDash(player)
				end
			end
		end
	end
	function self:locomotion(player, humanoid, state)
		humanoid.WalkSpeed = if state.Guard then 8 elseif state.Sprint and not state.Attack then 24 else 17
	end
	function self:remove(player)
		self:stopDash(player)
		self.Samples[player] = nil
	end
	return self
end
return Movement
