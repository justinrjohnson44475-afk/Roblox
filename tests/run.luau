--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local Config = require("../src/shared/Config")
local Profile = require("../src/shared/Profile")
local Progression = require("../src/shared/Progression")
local Combat = require("../src/shared/Combat")
local EnemyAI = require("../src/shared/EnemyAI")
local Authority = require("../src/shared/Authority")
local RateLimit = require("../src/shared/RateLimit")
local Economy = require("../src/shared/Economy")
local passed = 0
local function test(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		error("FAIL " .. name .. ": " .. tostring(err))
	end
	passed += 1
	print("PASS " .. name)
end
local function equal(a, b)
	assert(a == b, string.format("expected %s, got %s", tostring(b), tostring(a)))
end
local function rejects(fn)
	equal(pcall(fn), false)
end

test("new hero has schema 2 and no unearned progression", function()
	local p = Profile.new()
	equal(p.Schema, 2)
	equal(p.XP, 0)
	equal(p.Form, 0)
	equal(p.Cores, 0)
	equal(p.Owned.amber, true)
end)
test("legacy harbor data migrates without deleting cosmetic balances", function()
	local p = Profile.decode({
		Schema = 1,
		Tokens = 72,
		Donated = 36,
		Repairs = 3,
		Owned = { sea = true },
		Equipped = "sea",
	})
	equal(p.Schema, 2)
	equal(p.Tokens, 72)
	equal(p.Donated, 36)
	equal(p.Repairs, 3)
	equal(p.Equipped, "sea")
	equal(p.XP, 0)
end)
test("future schema refuses overwrite", function()
	rejects(function()
		Profile.decode({ Schema = 99 })
	end)
end)
test("corrupt root refuses overwrite", function()
	rejects(function()
		Profile.decode("bad")
	end)
end)
for _, value in { math.huge, -math.huge, 0 / 0, "999", {} } do
	test("nonfinite or nonnumeric progression rejected: " .. typeof(value), function()
		local p = Profile.new()
		p.Shards = value
		p.XP = value
		equal(Profile.decode(p).Shards, 0)
		equal(Profile.decode(p).XP, 0)
	end)
end
test("profile caps forged ranks/forms and unknown choices", function()
	local p = Profile.new()
	p.Form = 999
	p.Upgrades.power = 999
	p.Path = "admin"
	p.Equipped = "hacked"
	p.Owned.hacked = true
	local q = Profile.decode(p)
	equal(q.Form, 3)
	equal(q.Upgrades.power, 8)
	equal(q.Path, "vanguard")
	equal(q.Equipped, "amber")
	equal(q.Owned.hacked, nil)
end)
test("saved profile copy cannot alias mutable inventory, upgrades or clears", function()
	local p = Profile.new()
	local q = Profile.copy(p)
	q.Owned.sea = true
	q.Upgrades.power = 2
	q.Clears.verdant_warden = true
	equal(p.Owned.sea, nil)
	equal(p.Upgrades.power, 0)
	equal(p.Clears.verdant_warden, nil)
end)
test("XP thresholds and boundary levels are consistent", function()
	for level = 1, 15 do
		equal(Progression.level(Progression.threshold(level)), level)
		if level > 1 then
			equal(Progression.level(Progression.threshold(level) - 1), level - 1)
		end
	end
	equal(Progression.level(1000000000), 15)
end)
test("region gate requires BOTH level and prior warden", function()
	local p = Profile.new()
	local ember = Config.Regions[3]
	equal(Progression.canEnter(p, ember), false)
	p.XP = 1000
	equal(Progression.canEnter(p, ember), false)
	p.Clears.verdant_warden = true
	equal(Progression.canEnter(p, ember), true)
end)
test("upgrade cost is deterministic and cannot overspend", function()
	local p = Profile.new()
	p.Shards = 20
	equal(Progression.upgrade(p, "power", Config), true)
	equal(p.Shards, 0)
	equal(p.Upgrades.power, 1)
	equal(Progression.upgrade(p, "power", Config), false)
	equal(p.Shards, 0)
end)
for _, input in { {}, true, 999, "invalid", string.rep("x", 500) } do
	test("malformed forge upgrade rejected: " .. typeof(input), function()
		local p = Profile.new()
		p.Shards = 999
		equal(Progression.upgrade(p, input, Config), false)
		equal(p.Shards, 999)
	end)
end
test("maxed upgrades never charge again", function()
	local p = Profile.new()
	p.Shards = 999
	p.Upgrades.power = 8
	equal(Progression.upgrade(p, "power", Config), false)
	equal(p.Shards, 999)
end)
test("rig evolution requires milestone and consumes exact currencies once", function()
	local p = Profile.new()
	p.XP = 1000
	p.Shards = 100
	p.Cores = 1
	equal(Progression.evolve(p, Config), false)
	p.Clears.verdant_warden = true
	equal(Progression.evolve(p, Config), true)
	equal(p.Form, 1)
	equal(p.Shards, 65)
	equal(p.Cores, 0)
	equal(Progression.evolve(p, Config), false)
	equal(p.Shards, 65)
end)
test("path changes are earned, free and mechanically different", function()
	local p = Profile.new()
	equal(Progression.path(p, "strider", Config), false)
	p.XP = 100
	local original = Progression.stats(p, Config)
	equal(Progression.path(p, "strider", Config), true)
	local fast = Progression.stats(p, Config)
	assert(fast.DashCooldown < original.DashCooldown and fast.Health < original.Health)
	Progression.path(p, "arcanist", Config)
	local mage = Progression.stats(p, Config)
	assert(
		mage.Range > original.Range and mage.BurstCost < original.BurstCost and mage.Health < original.Health
	)
	equal(p.Shards, 0)
end)
test("first boss clear bonus applies once; ordinary replay rewards remain", function()
	local p = Profile.new()
	equal(Progression.reward(p, "verdant_warden", Config), true)
	equal(p.XP, 155)
	equal(p.Shards, 85)
	equal(p.Cores, 1)
	equal(Progression.reward(p, "verdant_warden", Config), false)
	equal(p.XP, 260)
	equal(p.Shards, 145)
	equal(p.Cores, 2)
end)
test("three-region route can unlock next capabilities without forced mob quotas", function()
	local p = Profile.new()
	for _ = 1, 3 do
		Progression.reward(p, "sentry", Config)
	end
	assert(Progression.level(p.XP) >= 2)
	Progression.reward(p, "verdant_warden", Config)
	equal(Progression.canEnter(p, Config.Regions[3]), true)
	equal(Progression.evolve(p, Config), true)
	for _ = 1, 3 do
		Progression.reward(p, "lancer", Config)
	end
	Progression.reward(p, "ember_warden", Config)
	equal(Progression.canEnter(p, Config.Regions[4]), true)
	assert(Progression.level(p.XP) >= 6)
	equal(Progression.evolve(p, Config), true)
	for _ = 1, 3 do
		Progression.reward(p, "lancer", Config)
	end
	Progression.reward(p, "astral_warden", Config)
	assert(Progression.level(p.XP) >= 8)
	equal(Progression.evolve(p, Config), true)
	equal(p.Form, 3)
end)
test("cosmetic reequipping does not double charge", function()
	local p = Profile.new()
	p.Tokens = 60
	equal(Economy.equip(p, "sea", Config), true)
	equal(p.Tokens, 30)
	Economy.equip(p, "amber", Config)
	Economy.equip(p, "sea", Config)
	equal(p.Tokens, 30)
end)
test("combat aim normalizes a finite horizontal vector", function()
	local aim = Combat.aim({ x = 3, y = 0, z = 4 })
	equal(aim.x, 0.6)
	equal(aim.z, 0.8)
	equal(aim.y, 0)
end)
for _, input in
	{
		{ x = 0, y = 0, z = 0 },
		{ x = math.huge, y = 0, z = 1 },
		{ x = 0 / 0, y = 0, z = 1 },
		{ x = "1", y = 0, z = 1 },
		{},
		true,
	}
do
	test("malformed aim rejected: " .. tostring(input), function()
		equal(Combat.aim(input), nil)
	end)
end
test("locked abilities and insufficient Focus cannot spend or start cooldown", function()
	local p = Profile.new()
	local stats = Progression.stats(p, Config)
	local s = Combat.new()
	s.Focus = 100
	equal(Combat.action(s, "burst", 10, stats, p.Path), false)
	equal(s.Focus, 100)
	equal(s.Last.burst, nil)
	p.XP = 40
	stats = Progression.stats(p, Config)
	s.Focus = 59
	equal(Combat.action(s, "burst", 10, stats, p.Path), false)
	equal(s.Focus, 59)
end)
test("burst consumes server Focus; spam is rejected", function()
	local p = Profile.new()
	p.XP = 40
	local stats = Progression.stats(p, Config)
	local s = Combat.new()
	s.Focus = 100
	equal(Combat.action(s, "burst", 10, stats, p.Path), true)
	equal(s.Focus, 40)
	equal(Combat.action(s, "burst", 10.2, stats, p.Path), false)
	equal(s.Focus, 40)
end)
test("strike combo has three steps and resets after a pause", function()
	local p = Profile.new()
	local stats = Progression.stats(p, Config)
	local s = Combat.new()
	local _, a = Combat.action(s, "strike", 10, stats, p.Path)
	local _, b = Combat.action(s, "strike", 10.5, stats, p.Path)
	local _, c = Combat.action(s, "strike", 11, stats, p.Path)
	equal(a.Combo, 1)
	equal(b.Combo, 2)
	equal(c.Combo, 3)
	assert(c.Damage > a.Damage)
	local _, reset = Combat.action(s, "strike", 14, stats, p.Path)
	equal(reset.Combo, 1)
end)
test("dash grants bounded invulnerability and a Strider follow-up", function()
	local p = Profile.new()
	p.XP = 100
	p.Path = "strider"
	local stats = Progression.stats(p, Config)
	local s = Combat.new()
	equal(Combat.action(s, "dash", 10, stats, p.Path), true)
	equal(s.DodgeUntil, 10.4)
	local _, follow = Combat.action(s, "strike", 10.3, stats, p.Path)
	assert(follow.Damage > stats.Damage)
	equal(s.FollowUntil, 0)
	equal(Combat.action(s, "dash", 10.5, stats, p.Path), false)
end)
test("coreburst breaks a solo boss charge and exposes it", function()
	local def = Config.Enemies.verdant_warden
	local e = EnemyAI.new(def, 0)
	equal(EnemyAI.step(e, def, 1, 3), "telegraph")
	local damage, broke = Combat.damage(e, 30, 1, 1.2, true, def)
	equal(broke, true)
	equal(e.State, "exposed")
	equal(damage, 45)
	equal(EnemyAI.step(e, def, 2, 3), nil)
	equal(e.State, "exposed")
end)
test("ordinary strike cannot falsely interrupt a charge", function()
	local def = Config.Enemies.sentry
	local e = EnemyAI.new(def, 0)
	EnemyAI.step(e, def, 1, 3)
	local _, broke = Combat.damage(e, 18, 1, 1.2, false, def)
	equal(broke, false)
	equal(e.State, "windup")
end)
test("windup impacts once, then respects recovery", function()
	local def = Config.Enemies.sentry
	local e = EnemyAI.new(def, 0)
	equal(EnemyAI.step(e, def, 1, 3), "telegraph")
	equal(EnemyAI.step(e, def, 1.5, 3), nil)
	equal(EnemyAI.step(e, def, 2.2, 3), "impact")
	equal(EnemyAI.step(e, def, 2.3, 3), nil)
	equal(e.State, "recovery")
end)
test("boss phase two changes cadence and alternates attack shape", function()
	local def = Config.Enemies.verdant_warden
	local e = EnemyAI.new(def, 0)
	e.Health = 200
	EnemyAI.step(e, def, 1, 3)
	equal(e.Phase, 2)
	equal(e.Pattern, "slam")
	assert(e.Until < 1 + def.Windup)
	EnemyAI.step(e, def, 3, 3)
	EnemyAI.step(e, def, 6, 3)
	equal(e.Pattern, "lance")
end)
test("distant enemies chase; no target means no new attack", function()
	local def = Config.Enemies.sentry
	local e = EnemyAI.new(def, 0)
	equal(EnemyAI.step(e, def, 1, 20), "move")
	equal(EnemyAI.step(e, def, 2, nil), nil)
	equal(e.State, "idle")
end)
test("damage cannot overkill and a dead enemy cannot reward twice", function()
	local def = Config.Enemies.sentry
	local e = EnemyAI.new(def, 0)
	equal(Combat.damage(e, 9999, 1, 10, false, def), 80)
	equal(e.Health, 0)
	equal(Combat.damage(e, 9999, 1, 11, false, def), 0)
	local recipients = Combat.recipients(e, 11)
	equal(#recipients, 1)
	equal(recipients[1], 1)
	equal(#Combat.recipients(e, 12), 0)
end)
test("recent contributing teammates qualify; stale or trivial tags do not", function()
	local def = Config.Enemies.verdant_warden
	local e = EnemyAI.new(def, 0)
	Combat.damage(e, 30, 1, 0, false, def)
	Combat.damage(e, 1, 2, 35, false, def)
	Combat.damage(e, 40, 3, 35, false, def)
	Combat.damage(e, 999, 4, 35, false, def)
	local ids = Combat.recipients(e, 36)
	local found = {}
	for _, id in ids do
		found[id] = true
	end
	equal(found[1], nil)
	equal(found[2], nil)
	equal(found[3], true)
	equal(found[4], true)
end)
test("forge and reward authority require live, close, correct-region players", function()
	equal(Authority.forge("verdant", 1, true), false)
	equal(Authority.forge("hub", 20, true), false)
	equal(Authority.forge("hub", 1, false), false)
	equal(Authority.forge("hub", 19, true), true)
	equal(Authority.reward("hub", "verdant", 1, true), false)
	equal(Authority.reward("verdant", "verdant", 66, true), false)
	equal(Authority.reward("verdant", "verdant", 10, true), true)
end)
test("NaN distance and implausible teleport cannot bypass authority", function()
	equal(Authority.near(0 / 0, 19), false)
	equal(Authority.movement(math.huge, 1), false)
	equal(Authority.movement(100, 0.1), false)
	equal(Authority.movement(4, 0.1), true)
end)
test("per-player rate limits isolate spam", function()
	local a, b = {}, {}
	equal(RateLimit.allow(a, "action", 10, 0.4), true)
	equal(RateLimit.allow(a, "action", 10.1, 0.4), false)
	equal(RateLimit.allow(b, "action", 10.1, 0.4), true)
end)

test("arrival activates one nearby sentry, not the whole region", function()
	local active = 0
	for _, spawn in Config.Spawns do
		if spawn.Region == "verdant" then
			local deltaX, deltaZ = spawn.Offset[1], spawn.Offset[3] - 34
			local d = math.sqrt(deltaX * deltaX + deltaZ * deltaZ)
			local def = Config.Enemies[spawn.Kind]
			if EnemyAI.canAcquire(EnemyAI.new(def, 0), def, d, d) then
				active += 1
			end
		end
	end
	equal(active, 1)
end)

local function dataHarness(studio)
	local storage = {}
	local fail = false
	local writes = 0
	local warnings = 0
	local now = 1000
	local id = "a"
	local store = {}
	function store:UpdateAsync(key, callback)
		writes += 1
		if fail then
			error("simulated outage")
		end
		local nextValue = callback(storage[key])
		if nextValue ~= nil then
			storage[key] = nextValue
		end
		return nextValue
	end
	local shared = { Config = "config", Profile = "profile" }
	local services = {
		DataStoreService = {
			GetDataStore = function()
				return store
			end,
		},
		RunService = {
			IsStudio = function()
				return studio
			end,
		},
		HttpService = {
			GenerateGUID = function()
				return id
			end,
		},
		ReplicatedStorage = {
			WaitForChild = function()
				return shared
			end,
		},
	}
	local function module()
		return luau.load(fs.readFile("src/server/DataService.luau"), {
			debugName = "DataServiceMock",
			injectGlobals = true,
			environment = {
				game = {
					JobId = "job",
					GetService = function(_, name)
						return services[name]
					end,
				},
				require = function(key)
					return if key == "config" then Config else Profile
				end,
				os = {
					time = function()
						return now
					end,
					clock = os.clock,
				},
				task = { wait = function() end },
				warn = function()
					warnings += 1
				end,
			},
		})()
	end
	local player = { UserId = 42, Attributes = {}, Parent = true }
	function player:SetAttribute(key, value)
		self.Attributes[key] = value
	end
	function player:Kick(message)
		self.Kicked = message
	end
	return {
		New = module,
		Player = player,
		Storage = storage,
		Fail = function(value)
			fail = value
		end,
		Advance = function(value)
			now += value
		end,
		Session = function(value)
			id = value
		end,
		Writes = function()
			return writes
		end,
	}
end

test("mock store: new profile saves and reloads", function()
	local h = dataHarness(false)
	local d = h.New()
	equal(d.load(h.Player), true)
	d.get(h.Player).Tokens = 88
	equal(d.save(h.Player, true), true)
	h.Session("b")
	local nextServer = h.New()
	equal(nextServer.load(h.Player), true)
	equal(nextServer.get(h.Player).Tokens, 88)
end)
test("active session lock prevents second load", function()
	local h = dataHarness(false)
	local first = h.New()
	first.load(h.Player)
	h.Session("b")
	local second = h.New()
	equal(second.load(h.Player), false)
	equal(h.Storage.player_42.Owner, "job:a")
end)
test("expired session can be acquired; old server cannot overwrite", function()
	local h = dataHarness(false)
	local first = h.New()
	first.load(h.Player)
	first.get(h.Player).Tokens = 900
	h.Advance(Config.LeaseSeconds + 1)
	h.Session("b")
	local second = h.New()
	equal(second.load(h.Player), true)
	equal(first.save(h.Player, false), false)
	equal(h.Storage.player_42.Owner, "job:b")
	equal(h.Storage.player_42.Data.Tokens, 0)
end)
test("future profile schema remains byte-for-byte untouched", function()
	local h = dataHarness(false)
	local old = { Data = { Schema = 99, Tokens = 123 }, LeaseUntil = 0 }
	h.Storage.player_42 = old
	equal(h.New().load(h.Player), false)
	equal(h.Storage.player_42, old)
end)
test("load outage never writes default data", function()
	local h = dataHarness(false)
	h.Fail(true)
	local d = h.New()
	equal(d.load(h.Player), false)
	equal(d.get(h.Player), nil)
	equal(h.Storage.player_42, nil)
end)
test("save outage retries boundedly and signals warning", function()
	local h = dataHarness(false)
	local d = h.New()
	d.load(h.Player)
	d.get(h.Player).Tokens = 10
	h.Fail(true)
	equal(d.save(h.Player, false), false)
	equal(h.Writes(), 4)
	equal(h.Player.Attributes.SaveWarning, true)
	equal(h.Storage.player_42.Data.Tokens, 0)
	h.Fail(false)
	equal(d.save(h.Player, false), true)
	equal(h.Player.Attributes.SaveWarning, false)
	equal(h.Storage.player_42.Data.Tokens, 10)
end)
test("lease expiry stops reward-bearing access", function()
	local h = dataHarness(false)
	local d = h.New()
	d.load(h.Player)
	h.Advance(Config.LeaseSeconds)
	equal(d.get(h.Player), nil)
	assert(h.Player.Kicked)
end)
test("Studio preview never accesses cloud storage", function()
	local h = dataHarness(true)
	local d = h.New()
	equal(d.load(h.Player), true)
	d.get(h.Player).Tokens = 10
	equal(d.save(h.Player, true), true)
	equal(h.Writes(), 0)
end)
test("save snapshots do not alias live inventory", function()
	local h = dataHarness(false)
	local d = h.New()
	d.load(h.Player)
	d.save(h.Player, false)
	d.get(h.Player).Owned.sea = true
	equal(h.Storage.player_42.Data.Owned.sea, nil)
end)

local function compileDirectory(path)
	for _, name in fs.readDir(path) do
		local full = path .. "/" .. name
		if fs.isDir(full) then
			compileDirectory(full)
		elseif name:match("%.luau$") then
			test("Luau compiles: " .. full, function()
				luau.compile(fs.readFile(full))
			end)
		end
	end
end
compileDirectory("src")
local env = table.clone(roblox)
local World = luau.load(fs.readFile("src/server/World.luau"), { environment = env, injectGlobals = true })()
local Appearance =
	luau.load(fs.readFile("src/server/Appearance.luau"), { environment = env, injectGlobals = true })()
test("authored world has four distinct regions and valid spawn markers", function()
	local world = World.build(Config)
	for _, region in Config.Regions do
		assert(world:FindFirstChild(region.Id))
		assert(world[region.Id]:FindFirstChild("Ground"))
	end
	for _, spawn in Config.Spawns do
		assert(world[spawn.Region]:FindFirstChild("Spawn_" .. spawn.Id))
	end
	local count = 0
	for _, item in world:GetDescendants() do
		if item:IsA("BasePart") then
			equal(item.Anchored, true)
			count += 1
		end
	end
	assert(count > 400 and count < 1200)
end)
test("forge and reading prompts are separate and no reading reward marker exists", function()
	local world = World.build(Config)
	assert(world.hub.ForgeStation:FindFirstChildOfClass("ProximityPrompt"))
	local reading = world.hub.ReadingBench:FindFirstChild("ChristianReading")
	assert(reading)
	equal(reading.Parent:GetAttribute("Destination"), nil)
	for _, key in { "Religion", "Reading", "Faith" } do
		equal(Profile.new()[key], nil)
	end
end)
test("each earned rig form changes visible geometry without collision", function()
	local previous = 0
	for form = 0, 3 do
		local character = roblox.Instance.new("Model")
		for _, name in { "Right Arm", "Torso" } do
			local part = roblox.Instance.new("Part")
			part.Name = name
			part.Parent = character
		end
		local rig = Appearance.rig(character, form, roblox.Color3.fromRGB(80, 220, 200), false)
		local count = 0
		for _, part in rig:GetDescendants() do
			if part:IsA("BasePart") then
				equal(part.CanCollide, false)
				count += 1
			end
		end
		assert(count > previous)
		previous = count
	end
end)
test("R15 hand and upper torso support the same rig", function()
	local character = roblox.Instance.new("Model")
	for _, name in { "RightHand", "UpperTorso" } do
		local part = roblox.Instance.new("Part")
		part.Name = name
		part.Parent = character
	end
	assert(Appearance.rig(character, 2, roblox.Color3.fromRGB(80, 220, 200), false))
end)
print(
	string.format(
		"\n%d checks passed. Mock/DOM verification only; Roblox engine and real players not tested.",
		passed
	)
)
