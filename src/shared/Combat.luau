--!strict
local Combat = {}
function Combat.finite(n): boolean
	return type(n) == "number" and n == n and math.abs(n) < 1000000
end
function Combat.aim(raw)
	if
		type(raw) ~= "table"
		or not Combat.finite(raw.x)
		or not Combat.finite(raw.y)
		or not Combat.finite(raw.z)
	then
		return nil
	end
	local magnitude = math.sqrt(raw.x * raw.x + raw.z * raw.z)
	if magnitude < 0.1 then
		return nil
	end
	return { x = raw.x / magnitude, y = 0, z = raw.z / magnitude }
end
function Combat.new()
	return { Focus = 0, Last = {}, Combo = 0, ComboAt = -100, DodgeUntil = 0, FollowUntil = 0 }
end
function Combat.action(s, action, now, stats, path)
	local cooldown = if action == "strike"
		then 0.48 * stats.CooldownScale
		elseif action == "dash" then stats.DashCooldown
		elseif action == "burst" then 4 * stats.CooldownScale
		elseif action == "overdrive" then 14
		else nil
	if not cooldown then
		return false, "Unknown action"
	end
	local last = s.Last[action]
	if last and now - last < cooldown then
		return false, "Cooling down"
	end
	if action == "burst" and stats.Level < 2 then
		return false, "Coreburst unlocks at level 2"
	end
	if action == "overdrive" and stats.Level < 5 then
		return false, "Overdrive unlocks at level 5"
	end
	local cost = if action == "burst" then stats.BurstCost elseif action == "overdrive" then 100 else 0
	if s.Focus < cost then
		return false, "Build Focus with successful strikes"
	end
	s.Focus -= cost
	s.Last[action] = now
	local damage = stats.Damage
	if action == "strike" then
		s.Combo = if now - s.ComboAt < 1.4 then s.Combo % 3 + 1 else 1
		s.ComboAt = now
		damage *= if s.Combo == 3 then 1.5 else 1
		if path == "strider" and s.FollowUntil > 0 and now <= s.FollowUntil then
			damage *= 1.35
			s.FollowUntil = 0
		end
	elseif action == "dash" then
		s.DodgeUntil = now + 0.4
		s.FollowUntil = now + 1.4
	elseif action == "burst" then
		damage *= if path == "arcanist" then 2.4 else 1.8
	elseif action == "overdrive" then
		damage *= 3.8
	end
	return true,
		{
			Damage = math.floor(damage),
			Radius = if action == "overdrive" then 23 else stats.BurstRadius,
			Combo = s.Combo,
		}
end
function Combat.damage(enemy, amount, userId, now, breaking: boolean, def)
	if enemy.Dead or amount <= 0 then
		return 0, false
	end
	local broke = false
	if breaking and enemy.State == "windup" then
		enemy.Poise += def.Poise
		if enemy.Poise >= def.Poise then
			enemy.State = "exposed"
			enemy.Until = now + 2.4
			enemy.Poise = 0
			broke = true
		end
	end
	local applied = math.min(enemy.Health, math.floor(amount * (if enemy.State == "exposed" then 1.5 else 1)))
	enemy.Health -= applied
	local contributor = enemy.Contributors[userId] or { Damage = 0, At = now }
	contributor.Damage += applied
	contributor.At = now
	enemy.Contributors[userId] = contributor
	if enemy.Health <= 0 then
		enemy.Dead = true
		enemy.State = "dead"
	end
	return applied, broke
end
function Combat.recipients(enemy, now)
	if not enemy.Dead or enemy.Rewarded then
		return {}
	end
	enemy.Rewarded = true
	local ids = {}
	for userId, contribution in enemy.Contributors do
		if now - contribution.At <= 30 and contribution.Damage >= math.min(20, enemy.MaxHealth * 0.05) then
			table.insert(ids, userId)
		end
	end
	return ids
end
return Combat
