--!strict
local Timeline = {}
function Timeline.new()
	return {
		Focus = 0,
		Stamina = 100,
		Attack = nil,
		Combo = 0,
		ComboAt = -100,
		Guard = false,
		GuardAt = -100,
		LockedUntil = 0,
		DodgeUntil = 0,
		LastDash = -100,
		FollowUntil = 0,
		Cooldowns = {},
		NextAttack = 0,
		LastSpend = -100,
		Sprint = false,
	}
end
function Timeline.begin(s, action, now, stats, definitions)
	if now < s.LockedUntil then
		return nil, "staggered"
	end
	if s.Attack then
		return nil, "committed"
	end
	local id
	if action == "light" then
		local combo = if now - s.ComboAt < 1.2 then s.Combo % 3 + 1 else 1
		id = "Light" .. combo
	elseif action == "heavy" then
		id = "Heavy"
	elseif action == "burst" then
		id = "Coreburst"
	elseif action == "overdrive" then
		id = "Overdrive"
	else
		return nil, "unknown"
	end
	local def = definitions[id]
	if id == "Coreburst" and stats.Level < 2 then
		return nil, "level"
	end
	if id == "Overdrive" and stats.Level < 5 then
		return nil, "level"
	end
	if now < (s.Cooldowns[id] or -100) then
		return nil, "cooldown"
	end
	local cost = if id == "Coreburst" then stats.BurstCost else def.FocusCost
	if s.Focus < cost or s.Stamina < def.StaminaCost then
		return nil, "resource"
	end
	s.Focus -= cost
	s.Stamina -= def.StaminaCost
	s.LastSpend = now
	s.Guard = false
	s.NextAttack += 1
	-- Flow shortens recovery only; authored active frames stay aligned to the animation.
	local recovery = def.Recovery * math.max(0.8, stats.CooldownScale)
	local a = {
		Id = s.NextAttack,
		Definition = id,
		Start = now,
		Previous = 0,
		EndAt = now + def.Windup + def.Active + recovery,
		Hits = {},
		HitCount = 0,
		MissSent = false,
	}
	s.Attack = a
	if action == "light" then
		s.Combo = tonumber(id:sub(-1))
		s.ComboAt = now
	end
	if id == "Coreburst" then
		s.Cooldowns[id] = now + 4 * stats.CooldownScale
	elseif id == "Overdrive" then
		s.Cooldowns[id] = now + 14
	end
	return a
end
function Timeline.advance(s, now, definitions)
	local a = s.Attack
	if not a then
		return nil
	end
	local def = definitions[a.Definition]
	local elapsed = math.max(0, now - a.Start)
	local from, to = math.max(a.Previous, def.Windup), math.min(elapsed, def.Windup + def.Active)
	local sweep = if to > from
		then {
			From = (from - def.Windup) / def.Active,
			To = (to - def.Windup) / def.Active,
			Attack = a,
			Definition = def,
		}
		else nil
	a.Previous = elapsed
	local finished = now >= a.EndAt
	if finished then
		s.Attack = nil
	end
	return sweep, if finished then a else nil
end
function Timeline.hit(attack, targetId): boolean
	if attack.Hits[targetId] then
		return false
	end
	attack.Hits[targetId] = true
	attack.HitCount += 1
	return true
end
function Timeline.guard(s, enabled, now)
	if enabled and (s.Attack or now < s.LockedUntil or s.Stamina < 10) then
		return false
	end
	if enabled and not s.Guard then
		s.GuardAt = now
	end
	s.Guard = enabled
	return true
end
function Timeline.defend(s, damage, now, facing, coreCharge, definitions)
	if now <= s.DodgeUntil then
		return 0, "dodge"
	end
	if not coreCharge and s.Guard and facing > 0.2 and now >= s.LockedUntil then
		if now - s.GuardAt <= definitions.Guard.ParryWindow then
			s.Focus = math.min(100, s.Focus + 15)
			return 0, "parry"
		end
		local cost = definitions.Guard.Cost
		if s.Stamina >= cost then
			s.Stamina -= cost
			s.LastSpend = now
			return damage * definitions.Guard.DamageScale, "block"
		end
		s.Stamina = 0
		s.Guard = false
		s.LockedUntil = now + definitions.Guard.BreakRecovery
		return damage, "guardbreak"
	end
	return damage, "hit"
end
function Timeline.dash(s, now, stats, definitions)
	if now < s.LockedUntil or now - s.LastDash < stats.DashCooldown or s.Stamina < definitions.Dash.Cost then
		return false
	end
	if s.Attack then
		local def = definitions[s.Attack.Definition]
		if now - s.Attack.Start < def.CancelAfter then
			return false
		end
		s.Attack = nil
	end
	s.Guard = false
	s.LastDash = now
	s.FollowUntil = now + 1.4
	s.DodgeUntil = now + definitions.Dash.Defense
	s.Stamina -= definitions.Dash.Cost
	s.LastSpend = now
	return true
end
function Timeline.regenerate(s, dt, now)
	dt = math.clamp(dt, 0, 0.1)
	if s.Sprint and s.Stamina > 0 then
		s.Stamina = math.max(0, s.Stamina - dt * 8)
		s.LastSpend = now
	elseif not s.Guard and now - s.LastSpend > 0.8 then
		s.Stamina = math.min(100, s.Stamina + dt * 22)
	end
	if s.Stamina <= 0 then
		s.Sprint = false
	end
end
return Timeline
