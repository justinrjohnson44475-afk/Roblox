--!strict
local Encounters = {}
function Encounters.new()
	return { Slots = {}, Serial = 0 }
end
function Encounters.allocate(s, roster, now)
	if #roster < 1 or #roster > 4 then
		return nil
	end
	local unique = {}
	for _, id in roster do
		if unique[id] then
			return nil
		end
		unique[id] = true
	end
	local slot
	for i = 1, 8 do
		if not s.Slots[i] then
			slot = i
			break
		end
	end
	if not slot then
		return nil
	end
	s.Serial += 1
	local e = {
		Id = "enc_" .. s.Serial,
		Slot = slot,
		Members = unique,
		Roster = table.clone(roster),
		Size = #roster,
		Scale = 1 + (#roster - 1) * 0.55,
		State = "active",
		Started = now,
		Departed = {},
		Rewards = {},
		EmptyAt = nil,
	}
	s.Slots[slot] = e
	return e
end
function Encounters.contains(e, user)
	return e.State == "active" and e.Members[user] == true and not e.Departed[user]
end
function Encounters.depart(e, user, now)
	if not e.Members[user] then
		return
	end
	e.Departed[user] = now
	local active = 0
	for id in e.Members do
		if not e.Departed[id] then
			active += 1
		end
	end
	if active == 0 then
		e.EmptyAt = now
	end
end
function Encounters.rejoin(e, user, now)
	local left = e.Departed[user]
	if e.State ~= "active" or not left or now - left > 60 then
		return false
	end
	e.Departed[user] = nil
	e.EmptyAt = nil
	return true
end
function Encounters.release(s, e)
	if s.Slots[e.Slot] == e then
		s.Slots[e.Slot] = nil
	end
	e.State = "closed"
end
return Encounters
