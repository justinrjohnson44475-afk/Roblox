--!strict
-- Preserve earned path tradeoffs while the legacy radius action is replaced by timed sweeps.
local Adapter = {}
function Adapter.accept(state, attack, stats, path, now)
	local multiplier = attack.Multiplier
	if attack.Id == "Coreburst" and path == "arcanist" then
		multiplier = 2.4
	end
	if
		attack.Id:sub(1, 5) == "Light"
		and path == "strider"
		and state.FollowUntil
		and state.FollowUntil > 0
		and now <= state.FollowUntil
	then
		multiplier *= 1.35
		state.FollowUntil = 0
	end
	return {
		Damage = math.floor(stats.Damage * multiplier),
		ReachScale = if attack.Id == "Coreburst"
			then stats.BurstRadius / 14
			elseif attack.Id == "Overdrive" then 23 / 14
			else stats.Range / 10,
	}
end
return Adapter
