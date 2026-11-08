--!strict
local Shift = {}
function Shift.new(config, now: number)
	return { Index = 1, Progress = 0, EndsAt = now + config.ShiftSeconds, Contributors = {}, Complete = false }
end
function Shift.add(state, userId: number, amount: number, config)
	if state.Complete then
		return false, {}
	end
	local project = config.Projects[state.Index]
	assert(
		amount > 0 and amount % 1 == 0 and amount <= project.Required - state.Progress,
		"Invalid contribution"
	)
	state.Progress += amount
	state.Contributors[userId] = true
	if state.Progress < project.Required then
		return false, {}
	end
	local participants = state.Contributors
	state.Contributors = {}
	state.Index += 1
	state.Progress = 0
	state.Complete = state.Index > #config.Projects
	return true, participants
end
return Shift
