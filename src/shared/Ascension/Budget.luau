--!strict
local Budget = {}
function Budget.new(capacity)
	return { Capacity = capacity, Active = {}, Count = 0, Serial = 0 }
end
function Budget.acquire(s, expires, priority)
	if s.Count >= s.Capacity then
		return nil
	end
	s.Serial += 1
	s.Active[s.Serial] = { Expires = expires, Priority = priority or 0 }
	s.Count += 1
	return s.Serial
end
function Budget.release(s, id)
	if not s.Active[id] then
		return false
	end
	s.Active[id] = nil
	s.Count -= 1
	return true
end
function Budget.expire(s, now)
	local expired = {}
	for id, item in s.Active do
		if now >= item.Expires then
			table.insert(expired, id)
			Budget.release(s, id)
		end
	end
	return expired
end
return Budget
