--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local WeaponSweep = require(Shared.Ascension.WeaponSweep)
local Distance = require(Shared.Ascension.Sweep)
local Choreography = require(Shared.Ascension.Choreography)
local Hitbox = {}
function Hitbox.canHit(world, character, origin, target, definition, from, to, reachScale)
	local root = target.PrimaryPart
	if not root or (root.Position - origin.Position).Magnitude > 12 * reachScale then
		return false
	end
	local offset = root.Position - origin.Position
	if offset.Magnitude > 0.01 and origin.LookVector:Dot(offset.Unit) < -0.15 then
		return false
	end
	local point = origin:PointToObjectSpace(root.Position)
	local localPoint = { x = point.X, y = point.Y, z = point.Z }
	local near = false
	for _, segment in
		WeaponSweep.segments(
			Choreography.Clips[definition.Animation],
			definition.Windup + from * definition.Active,
			definition.Windup + to * definition.Active,
			reachScale
		)
	do
		if Distance.distance(localPoint, segment.A, segment.B) <= 2.8 then
			near = true
			break
		end
	end
	if not near then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	params.RespectCanCollide = true
	local wall = world:Raycast(origin.Position, offset, params)
	return not wall or wall.Instance:IsDescendantOf(target)
end
return Hitbox
