--!strict
local Economy = {}
-- Config is passed explicitly to keep the domain runnable without Roblox services.
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
	return true, "Rig energy equipped"
end
return Economy
