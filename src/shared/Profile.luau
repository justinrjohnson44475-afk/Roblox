--!strict
local Profile = {}
export type Data = {
	Schema: number,
	Tokens: number,
	Donated: number,
	Repairs: number,
	Owned: { [string]: boolean },
	Equipped: string,
}
local function integer(value: any, fallback: number): number
	if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
		return fallback
	end
	return math.clamp(math.floor(value), 0, 1000000000)
end
function Profile.new(): Data
	return { Schema = 1, Tokens = 0, Donated = 0, Repairs = 0, Owned = { amber = true }, Equipped = "amber" }
end
function Profile.decode(raw: any): Data
	if raw == nil then
		return Profile.new()
	end
	assert(type(raw) == "table" and raw.Schema == 1, "Unsupported profile schema; refusing overwrite")
	local owned = { amber = true }
	for _, id in { "sea", "violet" } do
		if type(raw.Owned) == "table" and raw.Owned[id] == true then
			owned[id] = true
		end
	end
	local equipped = if type(raw.Equipped) == "string" and owned[raw.Equipped] then raw.Equipped else "amber"
	return {
		Schema = 1,
		Tokens = integer(raw.Tokens, 0),
		Donated = integer(raw.Donated, 0),
		Repairs = integer(raw.Repairs, 0),
		Owned = owned,
		Equipped = equipped,
	}
end
function Profile.copy(data: Data): Data
	return Profile.decode(data)
end
return Profile
