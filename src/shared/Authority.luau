--!strict
local Authority = {}
local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < 1000000
end
function Authority.near(distance, maximum): boolean
	return finite(distance) and distance >= 0 and distance <= maximum
end
function Authority.forge(region, distance, alive): boolean
	return alive == true and region == "hub" and Authority.near(distance, 19)
end
function Authority.reward(region, enemyRegion, distance, alive): boolean
	return alive == true and region == enemyRegion and Authority.near(distance, 65)
end
function Authority.movement(distance, elapsed): boolean
	return finite(elapsed) and elapsed >= 0 and Authority.near(distance, 18 + elapsed * 32)
end
return Authority
