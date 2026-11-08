--!strict
-- Engine-independent encounter choreography. Tick yields deliberate actions, not immediate damage.
local Warden = {}
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
	}
end
function Warden.tick(s, now, distance)
	if s.Health <= 0 then
		s.State = "defeated"
		return "defeated"
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
	if distance > 24 then
		return "navigate"
	end
	s.Counter += 1
	s.Pattern = if s.Counter % 3 == 0 then "core" elseif distance > 10 then "lance" else "melee"
	s.State = "windup"
	s.Charge = 0
	s.Applied = false
	s.Until = now + (if s.Pattern == "core" then 1.5 elseif s.Pattern == "lance" then 0.95 else 0.75)
	return "telegraph", s.Pattern
end
function Warden.damage(s, amount, breaker, now)
	if s.Health <= 0 then
		return 0, false
	end
	local broken = false
	if s.State == "windup" and s.Pattern == "core" and breaker then
		s.Charge += amount
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
