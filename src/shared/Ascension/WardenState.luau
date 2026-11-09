--!strict
-- Engine-independent encounter choreography. Tick yields deliberate actions, not immediate damage.
local Warden = {}
function Warden.contact(pattern)
	return if pattern == "core" then 1.57 elseif pattern == "lance" then 1.02 else 0.82
end
function Warden.new(health, now)
	return {
		Health = health,
		MaxHealth = health,
		Phase = 1,
		State = "approach",
		Until = now,
		Counter = 0,
		Charge = 0,
		Target = nil,
		Applied = false,
		Intro = true,
		PhaseShown = 1,
	}
end
function Warden.tick(s, now, distance)
	if s.Health <= 0 then
		s.State = "defeated"
		return "defeated"
	end
	if s.Intro then
		s.Intro = false
		s.State = "recovery"
		s.Until = now + 1.1
		return "roar"
	end
	s.Phase = if s.Health < s.MaxHealth * 0.5 then 2 else 1
	if s.State == "exposed" or s.State == "recovery" or s.State == "stagger" then
		if now < s.Until then
			return nil
		end
		s.State = "approach"
	end
	if s.State == "windup" then
		if now < s.Until then
			return nil
		end
		s.State = "active"
		s.Until = now + 0.18
		s.Applied = true
		return "impact", s.Pattern
	end
	if s.State == "active" then
		if now < s.Until then
			return nil
		end
		s.State = "recovery"
		s.Until = now + (if s.Phase == 2 then 0.65 else 1)
		return "recover"
	end
	if s.Phase > s.PhaseShown then
		s.PhaseShown = s.Phase
		s.State = "recovery"
		s.Until = now + 1.1
		return "roar"
	end
	if distance > 14 then
		return "navigate"
	end
	s.Counter += 1
	s.Pattern = if s.Counter % 3 == 0 then "core" elseif distance > 10 then "lance" else "melee"
	s.State = "windup"
	s.Charge = 0
	s.Applied = false
	s.Until = now + Warden.contact(s.Pattern)
	return "telegraph", s.Pattern
end
function Warden.damage(s, amount, breaker, now)
	if s.Health <= 0 then
		return 0, false
	end
	local broken = false
	if s.State == "windup" and s.Pattern == "core" and breaker then
		s.Charge += if breaker == "coreburst" then s.MaxHealth * 0.06 else amount
		if s.Charge >= s.MaxHealth * 0.06 then
			s.State = "exposed"
			s.Until = now + 3.5
			broken = true
		end
	end
	local dealt = amount * (if s.State == "exposed" then 1.75 else 1)
	s.Health = math.max(0, s.Health - dealt)
	return dealt, broken
end
function Warden.parry(s, now)
	if s.State == "active" and s.Pattern ~= "core" then
		s.State = "stagger"
		s.Until = now + 1.1
		return true
	end
	return false
end
return Warden
