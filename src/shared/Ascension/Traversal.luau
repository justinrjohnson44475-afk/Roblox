--!strict
-- Version 2 tuning follows the owner's stiff-movement playtest report.
local Traversal = {
	Version = 3,
	DashDuration = 0.18,
	SprintSpeed = 60,
	RunSpeed = 60,
	DoubleJumpVelocity = 48,
	WallDuration = 0.70,
	WallSpeed = 28,
	WallSteps = 5,
	WallCost = 12,
}
-- Reserved for future earned upgrades; no client packet can set this bonus.
function Traversal.runSpeed(earnedBonus)
	return Traversal.RunSpeed
		+ math.clamp(
			if type(earnedBonus) == "number" and earnedBonus == earnedBonus then earnedBonus else 0,
			0,
			30
		)
end
function Traversal.new()
	return {
		Grounded = false,
		GroundSince = nil,
		LeftAt = -100,
		ExtraUsed = false,
		WallUsed = false,
		WallUntil = 0,
		WallStep = 0,
	}
end
function Traversal.observe(s, grounded, now)
	if grounded then
		s.GroundSince = s.GroundSince or now
		if now - s.GroundSince >= 0.08 then
			s.ExtraUsed = false
			s.WallUsed = false
			s.WallUntil = 0
			s.WallStep = 0
		end
	else
		if s.Grounded then
			s.LeftAt = now
		end
		s.GroundSince = nil
	end
	s.Grounded = grounded
end
function Traversal.airJump(s, now)
	if s.Grounded or now - s.LeftAt < 0.10 or s.ExtraUsed then
		return false
	end
	s.ExtraUsed = true
	s.WallUntil = 0
	return true
end
function Traversal.wall(s, now, validSurface, stamina)
	if
		s.Grounded
		or s.WallUsed
		or now - s.LeftAt < 0.10
		or not validSurface
		or stamina < Traversal.WallCost
	then
		return false
	end
	s.WallUsed = true
	s.WallUntil = now + Traversal.WallDuration
	s.WallStep = 0
	return true
end
function Traversal.wallStep(s, now)
	if now >= s.WallUntil or s.WallUntil <= 0 then
		return nil
	end
	local elapsed = Traversal.WallDuration - (s.WallUntil - now)
	if elapsed < Traversal.WallDuration / Traversal.WallSteps * 0.5 then
		return nil
	end
	local step = math.min(
		Traversal.WallSteps,
		math.floor(
			(elapsed + Traversal.WallDuration / Traversal.WallSteps * 0.5)
				/ (Traversal.WallDuration / Traversal.WallSteps)
		)
	)
	if step <= s.WallStep then
		return nil
	end
	s.WallStep = step
	return step
end
function Traversal.dashSpeed(u, distance, duration)
	return distance / duration * (math.pi / 2) * math.sin(math.pi * math.clamp(u, 0, 1))
end
function Traversal.clip(kind, forward, right)
	if kind == "wall" then
		return if right > 0 then "WallRunLeft" else "WallRunRight"
	end
	if math.abs(right) > math.abs(forward) then
		return if right > 0 then "DashRight" else "DashLeft"
	end
	return if forward >= 0 then "DashForward" else "DashBack"
end
return table.freeze(Traversal)
