--!strict
local Profile = {}
local function integer(value, fallback)
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return fallback
	end
	return math.clamp(math.floor(value), 0, 1000000000)
end
function Profile.new()
	return {
		Schema = 2,
		XP = 0,
		Shards = 0,
		Cores = 0,
		Form = 0,
		Path = "vanguard",
		Upgrades = { power = 0, guard = 0, flow = 0 },
		Clears = {},
		Kills = 0,
		Owned = { amber = true },
		Equipped = "amber",
		Tokens = 0,
		Donated = 0,
		Repairs = 0,
	}
end
function Profile.decode(raw)
	if raw == nil then
		return Profile.new()
	end
	assert(
		type(raw) == "table" and (raw.Schema == 1 or raw.Schema == 2),
		"Unsupported profile schema; refusing overwrite"
	)
	local p = Profile.new()
	for _, key in { "XP", "Shards", "Cores", "Kills", "Tokens", "Donated", "Repairs" } do
		p[key] = integer(raw[key], 0)
	end
	-- Schema 1 harbor rewards stay available as legacy cosmetic tokens; never become paid/combat power.
	p.Form = math.min(integer(raw.Form, 0), 3)
	if raw.Path == "strider" or raw.Path == "arcanist" then
		p.Path = raw.Path
	end
	if type(raw.Upgrades) == "table" then
		for _, key in { "power", "guard", "flow" } do
			p.Upgrades[key] = math.min(integer(raw.Upgrades[key], 0), if key == "flow" then 6 else 8)
		end
	end
	if type(raw.Clears) == "table" then
		for _, key in { "verdant_warden", "ember_warden", "astral_warden" } do
			p.Clears[key] = raw.Clears[key] == true
		end
	end
	for _, id in { "sea", "violet" } do
		if type(raw.Owned) == "table" and raw.Owned[id] == true then
			p.Owned[id] = true
		end
	end
	if type(raw.Equipped) == "string" and p.Owned[raw.Equipped] then
		p.Equipped = raw.Equipped
	end
	return p
end
function Profile.copy(data)
	return Profile.decode(data)
end
return Profile
