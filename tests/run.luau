--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local Config = require("../src/shared/Config")
local Profile = require("../src/shared/Profile")
local Economy = require("../src/shared/Economy")
local Shift = require("../src/shared/Shift")
local RateLimit = require("../src/shared/RateLimit")
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

test("new profile has only free color", function()
	local p = Profile.new()
	equal(p.Tokens, 0)
	equal(p.Owned.amber, true)
	equal(p.Owned.sea, nil)
end)
test("profiles do not share inventory tables", function()
	local p = Profile.new()
	p.Owned.sea = true
	equal(Profile.new().Owned.sea, nil)
end)
test("nil data initializes safely", function()
	equal(Profile.decode(nil).Schema, 1)
end)
for _, value in { math.huge, -math.huge, 0 / 0, "900", {} } do
	test("invalid currency is sanitized: " .. tostring(value), function()
		local p = Profile.new()
		p.Tokens = value
		equal(Profile.decode(p).Tokens, 0)
	end)
end
test("negative and fractional counters normalized", function()
	local p = Profile.new()
	p.Tokens = -3
	p.Donated = 12.9
	equal(Profile.decode(p).Tokens, 0)
	equal(Profile.decode(p).Donated, 12)
end)
test("future schema refuses overwrite", function()
	rejects(function()
		Profile.decode({ Schema = 2 })
	end)
end)
test("corrupt root refuses overwrite", function()
	rejects(function()
		Profile.decode("bad")
	end)
end)
test("unknown cosmetics and unowned equipment removed", function()
	local p = Profile.new()
	p.Owned.hacked = true
	p.Equipped = "hacked"
	local clean = Profile.decode(p)
	equal(clean.Owned.hacked, nil)
	equal(clean.Equipped, "amber")
end)
test("profile copy does not alias saved inventory", function()
	local p = Profile.new()
	local q = Profile.copy(p)
	q.Owned.sea = true
	equal(p.Owned.sea, nil)
end)
test("contribution capped at exact project requirement", function()
	local p = Profile.new()
	equal(Economy.deposit(p, 5, 2, Config), 2)
	equal(p.Tokens, 4)
	equal(p.Donated, 2)
end)
test("negative contribution cannot mint currency", function()
	local p = Profile.new()
	equal(Economy.deposit(p, -5, 10, Config), 0)
	equal(p.Tokens, 0)
end)
test("empty or complete projects grant no reward", function()
	local p = Profile.new()
	equal(Economy.deposit(p, 5, 0, Config), 0)
	equal(p.Tokens, 0)
end)
test("insufficient tokens leave state unchanged", function()
	local p = Profile.new()
	equal(Economy.equip(p, "sea", Config), false)
	equal(p.Tokens, 0)
	equal(p.Equipped, "amber")
end)
test("purchase debits once; reequipping is free", function()
	local p = Profile.new()
	p.Tokens = 60
	equal(Economy.equip(p, "sea", Config), true)
	equal(p.Tokens, 30)
	Economy.equip(p, "amber", Config)
	Economy.equip(p, "sea", Config)
	equal(p.Tokens, 30)
end)
for _, value in { {}, 99, true, "unknown", string.rep("x", 1000) } do
	test("malformed cosmetic request rejected: " .. typeof(value), function()
		local p = Profile.new()
		equal(Economy.equip(p, value, Config), false)
		equal(p.Tokens, 0)
	end)
end
test("rate limit rejects repeats and allows boundary", function()
	local b = {}
	equal(RateLimit.allow(b, "a", 10, 1), true)
	equal(RateLimit.allow(b, "a", 10.9, 1), false)
	equal(RateLimit.allow(b, "a", 11, 1), true)
end)
test("players have independent rate limits", function()
	local b = {}
	RateLimit.allow(b, 1, 10, 1)
	equal(RateLimit.allow(b, 2, 10, 1), true)
end)
test("partial repair records contributors without completing", function()
	local s = Shift.new(Config, 0)
	equal(Shift.add(s, 1, 3, Config), false)
	equal(s.Progress, 3)
	equal(s.Contributors[1], true)
end)
test("completion rewards distinct participants once", function()
	local s = Shift.new(Config, 0)
	Shift.add(s, 1, 3, Config)
	Shift.add(s, 1, 2, Config)
	local done, participants = Shift.add(s, 2, 3, Config)
	equal(done, true)
	equal(participants[1], true)
	equal(participants[2], true)
	equal(s.Index, 2)
	equal(s.Progress, 0)
	equal(next(s.Contributors), nil)
end)
test("overfilled, negative and fractional repairs rejected", function()
	for _, amount in { 9, -1, 0, 0.5 } do
		rejects(function()
			Shift.add(Shift.new(Config, 0), 1, amount, Config)
		end)
	end
end)
test("full solo loop conserves supplies and rewards; replay resets shared state", function()
	local s = Shift.new(Config, 0)
	local p = Profile.new()
	local total = 0
	for _, project in Config.Projects do
		local remaining = project.Required
		while remaining > 0 do
			local amount = Economy.deposit(p, 5, remaining, Config)
			local done = Shift.add(s, 1, amount, Config)
			if done then
				p.Repairs += 1
			end
			remaining -= amount
			total += amount
		end
	end
	equal(total, 36)
	equal(p.Tokens, 72)
	equal(p.Donated, 36)
	equal(p.Repairs, 3)
	equal(s.Complete, true)
	equal(Shift.add(s, 1, 1, Config), false)
	local replay = Shift.new(Config, 300)
	equal(replay.Index, 1)
	equal(p.Tokens, 72)
end)
test("multi-player repair yields same tokens per unit", function()
	local s = Shift.new(Config, 0)
	local a, b = Profile.new(), Profile.new()
	Shift.add(s, 1, Economy.deposit(a, 5, 8, Config), Config)
	local done = Shift.add(s, 2, Economy.deposit(b, 5, 3, Config), Config)
	equal(done, true)
	equal(a.Tokens + b.Tokens, 16)
	equal(b.Donated, 3)
end)

-- Execute the actual persistence adapter with a deterministic mocked Roblox store.
-- These tests do not simulate Roblox budgets, shutdown or production network timing.
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

test("live new profile saves and reloads", function()
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

-- Syntax compilation is deliberately distinguished from a Roblox type/API check.
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

test("generated world contains eight supply prompts and three repairs", function()
	local env = table.clone(roblox)
	env.workspace = roblox.Instance.new("Workspace")
	local worldModule =
		luau.load(fs.readFile("src/server/World.luau"), { environment = env, injectGlobals = true })()
	local world = worldModule.build(Config)
	equal(#world.Supplies, 8)
	equal(#world.Projects, 3)
	local s = Shift.new(Config, 0)
	worldModule.render(world, s, Config)
	equal(world.Projects[1].Prompt.Enabled, true)
	equal(world.Projects[2].Prompt.Enabled, false)
	for _, project in Config.Projects do
		Shift.add(s, 1, project.Required, Config)
	end
	worldModule.render(world, s, Config)
	equal(world.Light.Enabled, true)
	for _, project in world.Projects do
		equal(project.Prompt.Enabled, false)
	end
	local reading = world.Folder:FindFirstChild("ReadingBench"):FindFirstChild("ChristianReading")
	assert(reading and reading:IsA("ProximityPrompt"))
end)
print(
	string.format("\n%d checks passed. Roblox engine, visual playtests and live services NOT tested.", passed)
)
