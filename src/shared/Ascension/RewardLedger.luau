--!strict
local Ledger = {}
function Ledger.seen(profile, id)
	for _, value in profile.RewardHistory do
		if value == id then
			return true
		end
	end
	return false
end
function Ledger.apply(profile, id, grant)
	assert(type(id) == "string" and #id > 0 and #id <= 128, "invalid server reward id")
	if Ledger.seen(profile, id) then
		return false
	end
	-- Grant and ledger entry are in the same profile snapshot / UpdateAsync envelope.
	grant(profile)
	table.insert(profile.RewardHistory, id)
	while #profile.RewardHistory > 64 do
		table.remove(profile.RewardHistory, 1)
	end
	return true
end
return Ledger
