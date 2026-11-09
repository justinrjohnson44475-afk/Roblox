--!strict
local WeaponSweep = {}
local function interpolate(samples, at)
	for i = 2, #samples do
		local a, b = samples[i - 1], samples[i]
		if at <= b.time then
			local t = math.clamp((at - a.time) / math.max(0.000001, b.time - a.time), 0, 1)
			local function p(key)
				return {
					x = a[key][1] + (b[key][1] - a[key][1]) * t,
					y = a[key][2] + (b[key][2] - a[key][2]) * t,
					z = a[key][3] + (b[key][3] - a[key][3]) * t,
				}
			end
			return p("base"), p("tip")
		end
	end
	local last = samples[#samples]
	return { x = last.base[1], y = last.base[2], z = last.base[3] }, {
		x = last.tip[1],
		y = last.tip[2],
		z = last.tip[3],
	}
end
function WeaponSweep.segments(clip, from, to, reachScale)
	local result = {}
	local count = math.clamp(math.ceil((to - from) * 120), 1, 32)
	local times = {}
	for i = 1, count do
		table.insert(times, from + (to - from) * i / count)
	end
	-- Include authored knots exactly: a narrow extreme between uniform samples must survive.
	for _, sample in clip.Samples do
		if sample.time > from and sample.time <= to then
			table.insert(times, sample.time)
		end
	end
	table.sort(times)
	local function points(at)
		local base, tip = interpolate(clip.Samples, at)
		local scale = reachScale or 1
		return base,
			{
				x = base.x + (tip.x - base.x) * scale,
				y = base.y + (tip.y - base.y) * scale,
				z = base.z + (tip.z - base.z) * scale,
			}
	end
	local previousBase, previousTip = points(from)
	local previousTime = from
	for _, at in times do
		if at <= previousTime then
			continue
		end
		local base, tip = points(at)
		table.insert(result, { A = base, B = tip })
		table.insert(result, { A = previousTip, B = tip })
		table.insert(result, { A = previousBase, B = base })
		previousBase, previousTip = base, tip
		previousTime = at
	end
	return result
end
return WeaponSweep
