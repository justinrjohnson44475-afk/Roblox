--!strict
local Economy = {}
-- Config is passed explicitly to keep the domain runnable without Roblox services.
function Economy.deposit(profile, carried: number, remaining: number, config): number
	local amount = math.min(math.max(0, math.floor(carried)), math.max(0, math.floor(remaining)))
	profile.Tokens += amount * config.TokensPerSupply
	profile.Donated += amount
	return amount
end
function Economy.equip(profile, id: any, config): (boolean, string)
	if type(id) ~= "string" or #id > 24 then
		return false, "Unknown cosmetic"
	end
	local cosmetic = config.Cosmetics[id]
	if not cosmetic then
		return false, "Unknown cosmetic"
	end
	if not profile.Owned[id] then
		if profile.Tokens < cosmetic.Cost then
			return false, "Not enough tokens"
		end
		profile.Tokens -= cosmetic.Cost
		profile.Owned[id] = true
	end
	profile.Equipped = id
	return true, "Lantern color equipped"
end
return Economy
