--!strict
local EnemyAI = {}
function EnemyAI.canAcquire(e, def, distance, homeDistance)
	local range = if e.State == "idle" then (if def.Boss then 40 else 26) else 55
	return homeDistance < 53 and distance <= range
end
function EnemyAI.new(def, now)
	return {
		Health = def.Health,
		MaxHealth = def.Health,
		State = "idle",
		Until = now + 0.7,
		Dead = false,
		Poise = 0,
		Attack = 0,
		Contributors = {},
		Rewarded = false,
		Phase = 1,
	}
end
-- Events are intents for the engine adapter; this state machine never applies client-reported damage.
function EnemyAI.step(e, def, now, distance)
	if e.Dead then
		return nil
	end
	e.Phase = if def.Boss and e.Health <= e.MaxHealth / 2 then 2 else 1
	if e.State == "windup" then
		if now >= e.Until then
			e.State = "recovery"
			e.Until = now + def.Recovery
			return "impact"
		end
		return nil
	end
	if e.State == "recovery" or e.State == "exposed" then
		if now < e.Until then
			return nil
		end
		e.State = "idle"
		e.Poise = 0
	end
	if not distance or distance > 55 then
		e.State = "idle"
		return nil
	end
	if distance > def.Reach then
		e.State = "chase"
		return "move"
	end
	e.Attack += 1
	e.Poise = 0
	e.State = "windup"
	e.Pattern = if def.Line or (def.Boss and e.Attack % 2 == 0) then "lance" else "slam"
	e.Until = now + def.Windup * (if e.Phase == 2 then 0.78 else 1)
	return "telegraph"
end
return EnemyAI
