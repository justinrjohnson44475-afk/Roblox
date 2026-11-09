--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Ledger = require(Shared.Ascension.RewardLedger)
local Progression = require(Shared.Progression)
local Rewards = {}
function Rewards.grant(player, dataService, config, encounterId, kind)
	local p = dataService.get(player)
	if not p then
		return false, "profile unavailable"
	end
	local changed = Ledger.apply(p, encounterId .. ":" .. kind, function(value)
		Progression.reward(value, kind, config)
	end)
	if not changed then
		return false, "already granted"
	end
	local saved = dataService.save(player, false)
	return true, if saved then "saved" else "save pending"
end
return Rewards
