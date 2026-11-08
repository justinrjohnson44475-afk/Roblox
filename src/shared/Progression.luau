--!strict
local Progression = {}
function Progression.threshold(level: number): number
	return (level - 1) * 40 + ((level - 1) * (level - 2) / 2) * 20
end
function Progression.level(xp: number): number
	local level = 1
	while level < 15 and xp >= Progression.threshold(level + 1) do
		level += 1
	end
	return level
end
function Progression.stats(p, config)
	local level = Progression.level(p.XP)
	local path = config.Paths[p.Path]
	return {
		Level = level,
		Health = math.floor((100 + (level - 1) * 6 + p.Upgrades.guard * 14 + p.Form * 12) * path.Health),
		Damage = math.floor((18 + (level - 1) * 2 + p.Upgrades.power * 3 + p.Form * 5) * path.Damage),
		CooldownScale = math.max(0.65, 1 - p.Upgrades.flow * 0.04),
		DashCooldown = 3.6 * path.Dash * math.max(0.65, 1 - p.Upgrades.flow * 0.04),
		Range = path.Range,
		BurstCost = path.BurstCost,
		BurstRadius = path.Radius,
	}
end
function Progression.canEnter(p, region)
	if Progression.level(p.XP) < region.Level then
		return false, "Requires level " .. region.Level
	end
	if region.Clear and not p.Clears[region.Clear] then
		return false, "Defeat the previous region’s warden first"
	end
	return true, "Gate attuned"
end
function Progression.upgrade(p, id, config)
	if type(id) ~= "string" or #id > 24 or not config.Upgrades[id] then
		return false, "Unknown upgrade"
	end
	local def = config.Upgrades[id]
	local rank = p.Upgrades[id]
	if rank >= def.Max then
		return false, "Upgrade complete"
	end
	local cost = def.BaseCost + rank * def.Step
	if p.Shards < cost then
		return false, "Need " .. cost .. " shards"
	end
	p.Shards -= cost
	p.Upgrades[id] += 1
	return true, def.Name .. " upgraded"
end
function Progression.evolve(p, config)
	local nextForm = config.Forms[p.Form + 2]
	if not nextForm then
		return false, "Rig fully evolved"
	end
	if Progression.level(p.XP) < nextForm.Level then
		return false, "Requires level " .. nextForm.Level
	end
	if nextForm.Clear and not p.Clears[nextForm.Clear] then
		return false, "Defeat the required warden first"
	end
	if p.Shards < nextForm.Shards or p.Cores < nextForm.Cores then
		return false, "Need " .. nextForm.Shards .. " shards and " .. nextForm.Cores .. " cores"
	end
	p.Shards -= nextForm.Shards
	p.Cores -= nextForm.Cores
	p.Form += 1
	return true, "Rig evolved: " .. nextForm.Name
end
function Progression.path(p, id, config)
	if type(id) ~= "string" or #id > 24 or not config.Paths[id] then
		return false, "Unknown path"
	end
	if Progression.level(p.XP) < 3 then
		return false, "Build paths unlock at level 3"
	end
	p.Path = id
	return true, config.Paths[id].Name .. " equipped — no reset cost"
end
function Progression.reward(p, kind, config)
	local def = config.Enemies[kind]
	local first = def.Boss and not p.Clears[kind]
	p.XP += def.XP + (if first then 50 else 0)
	p.Shards += def.Shards + (if first then 25 else 0)
	p.Kills += 1
	if def.Boss then
		p.Cores += def.Cores
		p.Clears[kind] = true
	end
	return first == true
end
function Progression.goal(p, config): string
	local level = Progression.level(p.XP)
	if level < 2 then
		return "Defeat constructs in Verdant Reach · Coreburst unlocks at Lv.2"
	end
	if
		not p.Clears.verdant_warden
		and p.Shards >= 20
		and p.Upgrades.power + p.Upgrades.guard + p.Upgrades.flow == 0
	then
		return "First upgrade ready · return to the relic forge in Dawn Sanctuary"
	end
	if not p.Clears.verdant_warden then
		return "Break the Verdant Warden’s charge, then expose its core"
	end
	if p.Form == 0 then
		return "Return to the forge · evolve your rig to Awakened"
	end
	if not p.Clears.ember_warden then
		return "Enter Ember Scar · defeat the Cinder Colossus"
	end
	if p.Form < 2 and level >= 6 then
		return "Forge your Ascendant rig · new armor and orbit blades"
	end
	if not p.Clears.astral_warden then
		return "Reach Lv.6 and challenge The Crownless in Astral Crown"
	end
	if p.Form < 3 then
		return "Reach Lv.8 and forge the Stormforged rig"
	end
	return "Master another build path or improve your permanent upgrades"
end
return Progression
