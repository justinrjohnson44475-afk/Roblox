--!strict
local Protocol = { Version = 2 }
local allowed = {
	light = true,
	heavy = true,
	dash = true,
	airJump = true,
	wallrun = true,
	burst = true,
	overdrive = true,
	guard = true,
	sprint = true,
	partyCreate = true,
	partyInvite = true,
	partyAccept = true,
	partyLeave = true,
	ready = true,
	enter = true,
	state = true,
	upgrade = true,
	evolve = true,
	path = true,
	color = true,
	equip = true,
	settings = true,
	supporter = true,
}
local function finite(n)
	return type(n) == "number" and n == n and math.abs(n) < 1000000000000
end
function Protocol.newSession(id)
	return { Id = id, Sequence = 0, LastAt = -100, Tokens = 12, TokenAt = 0 }
end
function Protocol.decode(session, packet, now)
	if type(packet) ~= "table" or packet.version ~= Protocol.Version or packet.session ~= session.Id then
		return nil, "session"
	end
	if
		not finite(packet.seq)
		or packet.seq % 1 ~= 0
		or packet.seq <= session.Sequence
		or packet.seq > session.Sequence + 1024
	then
		return nil, "sequence"
	end
	if type(packet.action) ~= "string" or not allowed[packet.action] then
		return nil, "action"
	end
	local elapsed = math.max(0, now - session.TokenAt)
	session.Tokens = math.min(12, session.Tokens + elapsed * 15)
	session.TokenAt = now
	local release = (packet.action == "guard" or packet.action == "sprint") and packet.enabled == false
	if session.Tokens < 1 and not release then
		return nil, "rate"
	end
	local aim = nil
	if packet.aim ~= nil then
		if type(packet.aim) ~= "table" then
			return nil, "aim"
		end
		local a = packet.aim
		if
			not finite(a.x)
			or not finite(a.y)
			or not finite(a.z)
			or math.abs(a.x) > 2
			or math.abs(a.y) > 2
			or math.abs(a.z) > 2
		then
			return nil, "aim"
		end
		local length = math.sqrt(a.x * a.x + a.z * a.z)
		if length < 0.1 then
			return nil, "aim"
		end
		aim = { x = a.x / length, y = 0, z = a.z / length }
	end
	if packet.item ~= nil and (type(packet.item) ~= "string" or #packet.item > 32) then
		return nil, "item"
	end
	if
		packet.target ~= nil and (not finite(packet.target) or packet.target % 1 ~= 0 or packet.target <= 0)
	then
		return nil, "target"
	end
	if packet.enabled ~= nil and type(packet.enabled) ~= "boolean" then
		return nil, "enabled"
	end
	-- Advance only after the complete envelope is accepted; malformed packets do not change sequence.
	session.Sequence = packet.seq
	if not release then
		session.Tokens -= 1
	end
	session.LastAt = now
	return {
		Action = packet.action,
		Aim = aim,
		Item = packet.item,
		Target = packet.target,
		Enabled = packet.enabled,
		Sequence = packet.seq,
	}
end
return Protocol
