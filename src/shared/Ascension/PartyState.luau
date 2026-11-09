--!strict
local Parties = {}
function Parties.new()
	return { Groups = {}, Membership = {}, Invites = {}, Serial = 0 }
end
function Parties.create(s, owner)
	if s.Membership[owner] then
		return nil, "already grouped"
	end
	s.Serial += 1
	local id = "party_" .. s.Serial
	s.Groups[id] = { Id = id, Leader = owner, Members = { owner }, Ready = {}, Encounter = nil }
	s.Membership[owner] = id
	return s.Groups[id]
end
function Parties.invite(s, owner, target, now)
	local p = s.Groups[s.Membership[owner]]
	if not p or p.Leader ~= owner or p.Encounter or owner == target or s.Membership[target] then
		return false
	end
	if #p.Members >= 4 then
		return false
	end
	s.Invites[target] = { Party = p.Id, Expires = now + 30, Inviter = owner }
	return true
end
function Parties.accept(s, target, now)
	local invite = s.Invites[target]
	if not invite or now > invite.Expires or s.Membership[target] then
		return nil
	end
	local p = s.Groups[invite.Party]
	if not p or p.Encounter or #p.Members >= 4 then
		return nil
	end
	table.insert(p.Members, target)
	s.Membership[target] = p.Id
	s.Invites[target] = nil
	p.Ready = {}
	return p
end
function Parties.leave(s, user)
	local id = s.Membership[user]
	local p = id and s.Groups[id]
	if not p then
		return nil
	end
	for i, member in p.Members do
		if member == user then
			table.remove(p.Members, i)
			break
		end
	end
	s.Membership[user] = nil
	p.Ready = {}
	if #p.Members == 0 then
		s.Groups[id] = nil
	else
		p.Leader = p.Members[1]
	end
	return p
end
function Parties.ready(s, user, value)
	local p = s.Groups[s.Membership[user]]
	if not p or p.Encounter then
		return false
	end
	p.Ready[user] = value == true
	return true
end
function Parties.roster(s, owner)
	local p = s.Groups[s.Membership[owner]]
	if not p then
		return { owner }
	end
	if p.Leader ~= owner or p.Encounter then
		return nil
	end
	for _, user in p.Members do
		if not p.Ready[user] then
			return nil
		end
	end
	return table.clone(p.Members)
end
return Parties
