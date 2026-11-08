--!strict
local PathfindingService = game:GetService("PathfindingService")
local Navigation = {}
function Navigation.new()
	local self = { Tokens = 4, At = os.clock(), Actors = {}, Destroyed = false }
	function self:move(model, target, now)
		if self.Destroyed then
			return
		end
		local root = model.PrimaryPart
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			return
		end
		local actor = self.Actors[model]
		if not actor then
			actor = { Last = -100, Busy = false, Waypoints = nil, Index = 1, Generation = 0 }
			self.Actors[model] = actor
		end
		if now - actor.Last < 0.2 then
			return
		end
		actor.Last = now
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { model }
		local obstacle = workspace:Raycast(root.Position, target - root.Position, params)
		if not obstacle or (obstacle.Position - target).Magnitude < 4 then
			humanoid:MoveTo(target)
			return
		end
		self.Tokens = math.min(4, self.Tokens + (now - self.At) * 4)
		self.At = now
		if not actor.Busy and self.Tokens >= 1 and now - (actor.PathAt or -100) > 1 then
			self.Tokens -= 1
			actor.Busy = true
			actor.PathAt = now
			actor.Generation += 1
			local generation = actor.Generation
			task.spawn(function()
				local path = PathfindingService:CreatePath({
					AgentRadius = 2,
					AgentHeight = 7,
					AgentCanJump = true,
					WaypointSpacing = 5,
				})
				local ok = pcall(function()
					path:ComputeAsync(root.Position, target)
				end)
				if self.Destroyed or self.Actors[model] ~= actor or actor.Generation ~= generation then
					path:Destroy()
					return
				end
				actor.Busy = false
				if ok and path.Status == Enum.PathStatus.Success then
					actor.Waypoints = path:GetWaypoints()
					actor.Index = 2
					actor.FailedAt = nil
				else
					actor.Waypoints = nil
					actor.FailedAt = actor.FailedAt or now
				end
				path:Destroy()
			end)
		end
		local waypoint = actor.Waypoints and actor.Waypoints[actor.Index]
		if waypoint then
			if (root.Position - waypoint.Position).Magnitude < 4 then
				actor.Index += 1
			end
			if waypoint.Action == Enum.PathWaypointAction.Jump then
				humanoid.Jump = true
			end
			humanoid:MoveTo(waypoint.Position)
		else
			humanoid:MoveTo(root.Position)
		end
	end
	function self:remove(model)
		local a = self.Actors[model]
		if a then
			a.Generation += 1
		end
		self.Actors[model] = nil
	end
	function self:destroy()
		self.Destroyed = true
		self.Actors = {}
	end
	return self
end
return Navigation
