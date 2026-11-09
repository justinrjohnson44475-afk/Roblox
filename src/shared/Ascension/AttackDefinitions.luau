--!strict
-- Versioned choreography is the authority for timing; client markers never grant a hit.
local function attack(id, windup, active, recovery, multiplier, focus, stamina, sweep, impact)
	return {
		Id = id,
		Animation = id,
		Windup = windup,
		Active = active,
		Recovery = recovery,
		Duration = windup + active + recovery,
		Multiplier = multiplier,
		FocusCost = focus,
		StaminaCost = stamina,
		Sweep = sweep,
		Impact = impact,
		CancelAfter = windup + active,
		Markers = {
			Anticipation = 0,
			TrailOn = windup,
			HitStart = windup,
			HitEnd = windup + active,
			TrailOff = windup + active,
			Recovery = windup + active,
		},
	}
end
return table.freeze({
	Version = 2,
	Light1 = attack("Light1", 0.06, 0.09, 0.13, 1, 0, 0, "right", "light"),
	Light2 = attack("Light2", 0.07, 0.10, 0.14, 1.05, 0, 0, "left", "light"),
	Light3 = attack("Light3", 0.10, 0.12, 0.20, 1.5, 0, 0, "rise", "heavy"),
	Heavy = attack("Heavy", 0.35, 0.16, 0.40, 2.4, 0, 24, "down", "heavy"),
	Coreburst = attack("Coreburst", 0.12, 0.06, 0.30, 1.8, 60, 0, "pulse", "core"),
	Overdrive = attack("Overdrive", 0.25, 0.15, 0.60, 3.8, 100, 0, "pulse", "boss"),
	Dash = { Version = 2, Distance = 18, Duration = 0.18, Defense = 0.4, Cost = 20 },
	Guard = { ParryWindow = 0.16, DamageScale = 0.3, Cost = 18, BreakRecovery = 0.7 },
})
