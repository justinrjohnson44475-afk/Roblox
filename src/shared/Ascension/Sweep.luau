--!strict
-- Vector tables keep canonical hit trajectories runnable in Cloud without engine services.
local Sweep = {}
local function lerp(a, b, t)
	return { x = a.x + (b.x - a.x) * t, y = a.y + (b.y - a.y) * t, z = a.z + (b.z - a.z) * t }
end
function Sweep.point(kind, t, range)
	t = math.clamp(t, 0, 1)
	if kind == "down" then
		return { x = 0, y = 4 - 4 * t, z = -range * (0.5 + 0.5 * t) }
	end
	if kind == "rise" then
		return { x = -2 + 4 * t, y = -1 + 4 * t, z = -range * (0.7 + 0.3 * math.sin(t * math.pi)) }
	end
	local angle = (-65 + 130 * t) * math.pi / 180
	if kind == "left" then
		angle = -angle
	end
	return { x = math.sin(angle) * range, y = 1.2 + 0.4 * math.sin(t * math.pi), z = -math.cos(angle) * range }
end
function Sweep.segments(kind, a, b, range)
	local segments = {}
	local count = math.max(1, math.ceil((b - a) * 16))
	for i = 1, count do
		table.insert(segments, {
			A = Sweep.point(kind, a + (b - a) * (i - 1) / count, range),
			B = Sweep.point(kind, a + (b - a) * i / count, range),
		})
	end
	return segments
end
function Sweep.distance(point, a, b)
	local dx, dy, dz = b.x - a.x, b.y - a.y, b.z - a.z
	local denom = dx * dx + dy * dy + dz * dz
	local t = if denom > 0
		then math.clamp(((point.x - a.x) * dx + (point.y - a.y) * dy + (point.z - a.z) * dz) / denom, 0, 1)
		else 0
	local nearest = lerp(a, b, t)
	return math.sqrt((point.x - nearest.x) ^ 2 + (point.y - nearest.y) ^ 2 + (point.z - nearest.z) ^ 2)
end
return Sweep
