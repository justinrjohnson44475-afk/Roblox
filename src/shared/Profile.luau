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
		Schema = 3,
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
		Loadout = { Weapon = "relic_blade", Skin = "default" },
		Customization = { Body = "dawn", Hair = "swept", Skin = "medium" },
		Settings = { Music = 0.6, Effects = 0.8, Motion = 0.2, Flash = 0, UIScale = 1, Quality = "auto" },
		RewardHistory = {},
	}
end
function Profile.decode(raw)
	if raw == nil then
		return Profile.new()
	end
	assert(
		type(raw) == "table" and (raw.Schema == 1 or raw.Schema == 2 or raw.Schema == 3),
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
	if type(raw.Loadout) == "table" then
		if raw.Loadout.Weapon == "relic_blade" then
			p.Loadout.Weapon = raw.Loadout.Weapon
		end
		if raw.Loadout.Skin == "default" or raw.Loadout.Skin == "tidal" or raw.Loadout.Skin == "astral" then
			p.Loadout.Skin = raw.Loadout.Skin
		end
	end
	if type(raw.Customization) == "table" then
		local choices = {
			Body = { dawn = true, dusk = true },
			Hair = { swept = true, braided = true, cropped = true },
			Skin = { light = true, warm = true, medium = true, tan = true, brown = true, deep = true },
		}
		for key, allowed in choices do
			if type(raw.Customization[key]) == "string" and allowed[raw.Customization[key]] then
				p.Customization[key] = raw.Customization[key]
			end
		end
	end
	if type(raw.Settings) == "table" then
		for _, key in { "Music", "Effects", "Motion", "Flash", "UIScale" } do
			local value = raw.Settings[key]
			if type(value) == "number" and value == value and math.abs(value) < math.huge then
				p.Settings[key] = math.clamp(
					value,
					if key == "UIScale" then 0.8 else 0,
					if key == "UIScale" then 1.4 else 1
				)
			end
		end
		if raw.Settings.Quality == "low" or raw.Settings.Quality == "high" then
			p.Settings.Quality = raw.Settings.Quality
		end
	end
	if type(raw.RewardHistory) == "table" then
		local seen = {}
		for _, id in raw.RewardHistory do
			if type(id) == "string" and #id > 0 and #id <= 128 and not seen[id] then
				table.insert(p.RewardHistory, id)
				seen[id] = true
			end
			if #p.RewardHistory >= 64 then
				break
			end
		end
	end
	return p
end
function Profile.copy(data)
	return Profile.decode(data)
end
return Profile
