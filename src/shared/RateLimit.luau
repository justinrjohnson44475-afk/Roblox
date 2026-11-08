--!strict
local RateLimit = {}
function RateLimit.allow(bucket, key, now: number, interval: number): boolean
	local previous = bucket[key]
	if previous and now - previous < interval then
		return false
	end
	bucket[key] = now
	return true
end
return RateLimit
