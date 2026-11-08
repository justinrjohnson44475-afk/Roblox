--!strict
return function(test, equal)
	local BuildAdapter = require("../../src/shared/Ascension/BuildAdapter")
	local Protocol = require("../../src/shared/Ascension/Protocol")
	local Timeline = require("../../src/shared/Ascension/CombatTimeline")
	local Def = require("../../src/shared/Ascension/AttackDefinitions")
	local Warden = require("../../src/shared/Ascension/WardenState")
	local Parties = require("../../src/shared/Ascension/PartyState")
	local Encounters = require("../../src/shared/Ascension/EncounterState")
	local Ledger = require("../../src/shared/Ascension/RewardLedger")
	local Budget = require("../../src/shared/Ascension/Budget")
	local Readiness = require("../../src/shared/Ascension/AssetReadiness")
	local Sweep = require("../../src/shared/Ascension/Sweep")
	local Weapon = require("../../src/shared/Ascension/WeaponSweep")
	local Profile = require("../../src/shared/Profile")
	local fs = require("@lune/fs")
	local serde = require("@lune/serde")
	local R = require("@lune/roblox")
	local stats = { Level = 5, CooldownScale = 1, BurstCost = 60, DashCooldown = 3.6 }
	test("versioned light and heavy windows retain approved initial timings", function()
		for id, values in
			{
				Light1 = { 0.10, 0.12, 0.20 },
				Light2 = { 0.12, 0.12, 0.22 },
				Light3 = { 0.17, 0.15, 0.29 },
				Heavy = {
					0.35,
					0.12,
					0.43,
				},
			}
		do
			equal(Def[id].Windup, values[1])
			equal(Def[id].Active, values[2])
			equal(Def[id].Recovery, values[3])
		end
	end)
	test("request session replay malformed aim and future sequence rejection", function()
		local s = Protocol.newSession("one")
		assert(not Protocol.decode(s, { version = 2, session = "two", seq = 1, action = "light" }, 1))
		assert(
			not Protocol.decode(
				s,
				{ version = 2, session = "one", seq = 1, action = "light", aim = { x = 0 / 0, y = 0, z = 1 } },
				1
			)
		)
		equal(s.Sequence, 0)
		assert(
			Protocol.decode(
				s,
				{ version = 2, session = "one", seq = 1, action = "light", aim = { x = 1, y = 1, z = 0 } },
				1
			)
		)
		assert(not Protocol.decode(s, { version = 2, session = "one", seq = 1, action = "light" }, 2))
		assert(not Protocol.decode(s, { version = 2, session = "one", seq = 2049, action = "light" }, 2))
	end)
	test("request token bucket bounds a burst and refills", function()
		local s = Protocol.newSession("x")
		for i = 1, 12 do
			assert(Protocol.decode(s, { version = 2, session = "x", seq = i, action = "light" }, 1))
		end
		assert(not Protocol.decode(s, { version = 2, session = "x", seq = 13, action = "light" }, 1))
		assert(Protocol.decode(s, { version = 2, session = "x", seq = 13, action = "light" }, 2))
	end)
	test("guard release survives exhausted combat bucket and real user IDs remain valid", function()
		local s = Protocol.newSession("a")
		s.Tokens = 0
		s.TokenAt = 1
		assert(
			Protocol.decode(s, { version = 2, session = "a", seq = 1, action = "guard", enabled = false }, 1)
		)
		equal(s.Tokens, 0)
		assert(
			Protocol.decode(
				s,
				{ version = 2, session = "a", seq = 2, action = "partyInvite", target = 350898717 },
				2
			)
		)
		assert(
			not Protocol.decode(
				s,
				{ version = 2, session = "a", seq = 3, action = "light", aim = { x = 10, y = 0, z = 0 } },
				2
			)
		)
	end)

	test("damage waits for active window and skipped frames retain sweep interval", function()
		local s = Timeline.new()
		local a = Timeline.begin(s, "light", 10, stats, Def)
		assert(a)
		equal(Timeline.advance(s, 10.09, Def), nil)
		local sweep, finished = Timeline.advance(s, 10.5, Def)
		assert(sweep and finished)
		equal(sweep.From, 0)
		assert(math.abs(sweep.To - 1) < 0.000001)
		equal(s.Attack, nil)
		equal(Timeline.advance(s, 11, Def), nil)
	end)
	test("one target receives one hit per accepted attack", function()
		local s = Timeline.new()
		local a = Timeline.begin(s, "light", 1, stats, Def)
		assert(Timeline.hit(a, "warden"))
		equal(Timeline.hit(a, "warden"), false)
		equal(a.HitCount, 1)
	end)
	test("three light transitions reset after inactivity and reject overlapping commitment", function()
		local s = Timeline.new()
		for i = 1, 3 do
			local at = i * 0.7
			local a = Timeline.begin(s, "light", at, stats, Def)
			equal(a.Definition, "Light" .. i)
			assert(not Timeline.begin(s, "heavy", at + 0.01, stats, Def))
			Timeline.advance(s, at + 0.65, Def)
		end
		equal(Timeline.begin(s, "light", 6, stats, Def).Definition, "Light1")
	end)
	test("dash cancels only recovery and preserves distance and defense", function()
		local s = Timeline.new()
		Timeline.begin(s, "light", 1, stats, Def)
		assert(not Timeline.dash(s, 1.15, stats, Def))
		assert(Timeline.dash(s, 1.23, stats, Def))
		equal(s.Attack, nil)
		equal(s.Stamina, 80)
		equal(Def.Dash.Distance, 18)
		equal(Def.Dash.Duration, 0.22)
		equal(s.DodgeUntil, 1.63)
		assert(not Timeline.dash(s, 2, stats, Def))
		equal(Timeline.defend(s, 40, 1.4, 1, true, Def), 0)
	end)
	test("guard parry is directional and core charges cannot be guarded", function()
		local s = Timeline.new()
		assert(Timeline.guard(s, true, 10))
		local damage, result = Timeline.defend(s, 40, 10.1, 1, false, Def)
		equal(damage, 0)
		equal(result, "parry")
		equal(Timeline.defend(s, 40, 10.1, -1, false, Def), 40)
		equal(Timeline.defend(s, 40, 10.1, 1, true, Def), 40)
		local d, r = Timeline.defend(s, 40, 10.3, 1, false, Def)
		equal(d, 12)
		equal(r, "block")
		equal(s.Stamina, 82)
	end)
	test("insufficient block stamina causes bounded guard break", function()
		local s = Timeline.new()
		s.Stamina = 12
		Timeline.guard(s, true, 10)
		local _, result = Timeline.defend(s, 30, 10.5, 1, false, Def)
		equal(result, "guardbreak")
		equal(s.Stamina, 0)
		equal(s.Guard, false)
		assert(not Timeline.begin(s, "light", 10.6, stats, Def))
		assert(Timeline.begin(s, "light", 11.3, stats, Def))
	end)
	test("resource and earned-level gates precede attack acceptance", function()
		local s = Timeline.new()
		assert(not Timeline.begin(s, "burst", 1, stats, Def))
		equal(s.Focus, 0)
		s.Focus = 100
		local low = table.clone(stats)
		low.Level = 1
		assert(not Timeline.begin(s, "burst", 1, low, Def))
		equal(s.Focus, 100)
		assert(Timeline.begin(s, "burst", 1, stats, Def))
		equal(s.Focus, 40)
	end)
	test("earned build adapter retains Strider follow-up and Arcanist burst/reach", function()
		local s = Timeline.new()
		local values = { Damage = 20, Range = 15, BurstRadius = 15 }
		assert(Timeline.dash(s, 1, stats, Def))
		local first = BuildAdapter.accept(s, Def.Light1, values, "strider", 1.5)
		equal(first.Damage, 27)
		equal(first.ReachScale, 1.5)
		equal(BuildAdapter.accept(s, Def.Light1, values, "strider", 1.6).Damage, 20)
		equal(BuildAdapter.accept(s, Def.Coreburst, values, "arcanist", 2).Damage, 48)
	end)

	test("Warden telegraphs before impact and breaks into exposure", function()
		local w = Warden.new(600, 0)
		w.Counter = 2
		local action, pattern = Warden.tick(w, 1, 5)
		equal(action, "telegraph")
		equal(pattern, "core")
		equal(Warden.tick(w, 2, 5), nil)
		local damage, broken = Warden.damage(w, 40, true, 2)
		assert(broken)
		equal(damage, 70)
		equal(w.State, "exposed")
		equal(Warden.tick(w, 3, 5), nil)
		equal(w.Health, 530)
	end)
	test("Warden basic attack can be parried and core cannot", function()
		local w = Warden.new(600, 0)
		equal(Warden.tick(w, 1, 5), "telegraph")
		equal(Warden.tick(w, 2, 5), "impact")
		assert(Warden.parry(w, 2))
		equal(w.State, "stagger")
		w.State = "active"
		w.Pattern = "core"
		equal(Warden.parry(w, 3), false)
	end)
	test("party invitations expire and only leader may invite", function()
		local s = Parties.new()
		local p = Parties.create(s, 1)
		assert(p)
		assert(Parties.invite(s, 1, 2, 1))
		equal(Parties.accept(s, 2, 32), nil)
		assert(Parties.invite(s, 1, 2, 33))
		assert(Parties.accept(s, 2, 34))
		equal(Parties.invite(s, 2, 3, 34), false)
		equal(Parties.roster(s, 1), nil)
		Parties.ready(s, 1, true)
		Parties.ready(s, 2, true)
		equal(#Parties.roster(s, 1), 2)
	end)
	test("party readiness resets on membership change and capacity stays four", function()
		local s = Parties.new()
		local p = Parties.create(s, 1)
		for i = 2, 4 do
			assert(Parties.invite(s, 1, i, 1))
			assert(Parties.accept(s, i, 2))
		end
		assert(not Parties.invite(s, 1, 5, 2))
		Parties.ready(s, 1, true)
		Parties.leave(s, 1)
		equal(p.Leader, 2)
		p.Encounter = "frozen"
		assert(not Parties.invite(s, 2, 5, 3))
		assert(not Parties.roster(s, 2))
	end)
	test("encounter roster ownership scale and reconnect remain frozen", function()
		local s = Encounters.new()
		local e = Encounters.allocate(s, { 1, 2, 3, 4 }, 1)
		assert(math.abs(e.Scale - 2.65) < 0.000001)
		assert(not Encounters.contains(e, 5))
		Encounters.depart(e, 2, 2)
		assert(not Encounters.contains(e, 2))
		equal(e.Size, 4)
		assert(math.abs(e.Scale - 2.65) < 0.000001)
		assert(Encounters.rejoin(e, 2, 61))
		Encounters.depart(e, 2, 62)
		assert(not Encounters.rejoin(e, 2, 123))
		Encounters.release(s, e)
		equal(e.State, "closed")
		equal(s.Slots[1], nil)
	end)
	test("encounter pool exhaustion and duplicate roster rejected", function()
		local s = Encounters.new()
		assert(not Encounters.allocate(s, { 1, 1 }, 1))
		for i = 1, 8 do
			assert(Encounters.allocate(s, { i }, 1))
		end
		assert(not Encounters.allocate(s, { 9 }, 1))
	end)
	test("reward retries mutate balances once and ledger remains bounded", function()
		local p = Profile.new()
		local function grant(v)
			v.Shards += 10
		end
		assert(Ledger.apply(p, "server:enc:warden", grant))
		assert(not Ledger.apply(p, "server:enc:warden", grant))
		equal(p.Shards, 10)
		for i = 1, 80 do
			Ledger.apply(p, "server:" .. i, grant)
		end
		equal(#p.RewardHistory, 64)
		equal(p.Shards, 810)
	end)
	test("schema two upgrades clear flags cosmetics and balances survive additive migration", function()
		local raw = {
			Schema = 2,
			XP = 400,
			Shards = 75,
			Cores = 8,
			Form = 2,
			Path = "strider",
			Upgrades = { power = 4, guard = 3, flow = 2 },
			Clears = { verdant_warden = true, ember_warden = true },
			Owned = { violet = true },
			Equipped = "violet",
			Tokens = 19,
			Donated = 7,
			Repairs = 2,
			Kills = 50,
		}
		local p = Profile.decode(raw)
		equal(p.Schema, 3)
		equal(p.XP, 400)
		equal(p.Shards, 75)
		equal(p.Cores, 8)
		equal(p.Path, "strider")
		equal(p.Form, 2)
		equal(p.Upgrades.power, 4)
		assert(p.Clears.ember_warden)
		equal(p.Equipped, "violet")
		equal(p.Tokens, 19)
		equal(p.Donated, 7)
		equal(p.Loadout.Weapon, "relic_blade")
		equal(#p.RewardHistory, 0)
		p.Upgrades.power = 5
		equal(raw.Upgrades.power, 4)
	end)
	test("schema three rejects invalid settings and bounds dedup data", function()
		local raw = Profile.new()
		raw.Settings.Music = 0 / 0
		raw.Settings.Motion = -2
		raw.Settings.UIScale = 5
		for i = 1, 100 do
			table.insert(raw.RewardHistory, "x" .. i)
		end
		local p = Profile.decode(raw)
		equal(p.Settings.Music, 0.6)
		equal(p.Settings.Motion, 0)
		equal(p.Settings.UIScale, 1.4)
		equal(#p.RewardHistory, 64)
		local copy = Profile.copy(p)
		copy.Customization.Body = "dusk"
		equal(p.Customization.Body, "dawn")
	end)
	test("unpublished assets visibly block readiness and Studio preview never passes gate", function()
		local manifest = {
			Version = 1,
			Assets = {
				hero = {
					Required = true,
					RobloxId = 0,
					Status = "exported",
					LicenseVerified = true,
				},
			},
		}
		equal(Readiness.evaluate(manifest, false).Mode, "blocked")
		equal(Readiness.evaluate(manifest, true).Ready, false)
		manifest.Assets.hero.RobloxId = 123
		manifest.Assets.hero.Status = "imported"
		equal(Readiness.evaluate(manifest, true).Ready, false)
		manifest.Assets.hero.Status = "engine-validated"
		manifest.Assets.hero.Owner = "test-owner"
		manifest.Assets.hero.EngineEvidence = "test fixture only"
		assert(Readiness.evaluate(manifest, false).Ready)
	end)
	test("effects pool exhaustion expiration reuse and repeated cleanup remain bounded", function()
		local s = Budget.new(96)
		for cycle = 1, 100 do
			local ids = {}
			for i = 1, 96 do
				table.insert(ids, Budget.acquire(s, cycle, 0))
			end
			equal(s.Count, 96)
			equal(Budget.acquire(s, cycle, 0), nil)
			equal(#Budget.expire(s, cycle), 96)
			equal(s.Count, 0)
			assert(not Budget.release(s, ids[1]))
		end
	end)
	test("measured blade sweeps are finite and segment distance handles zero length", function()
		local data = serde.decode("json", fs.readFile("assets/ascension/animations/choreography.json"))
		for _, id in { "Light1", "Light2", "Light3", "Heavy", "Coreburst", "Overdrive" } do
			local clip = data.clips[id]
			local def = Def[id]
			assert(math.abs(clip.duration - def.Duration) < 0.00001)
			equal(clip.markers.HitStart, def.Windup)
			assert(math.abs(clip.markers.HitEnd - def.Windup - def.Active) < 0.000001)
			local segments = Weapon.segments({ Samples = clip.sweep }, def.Windup, def.Windup + def.Active)
			assert(#segments > 0 and #segments <= 96)
			local reachesForward = false
			for _, segment in segments do
				if segment.A.z < -3 or segment.B.z < -3 then
					reachesForward = true
				end
			end
			assert(reachesForward, id .. " blade never reaches forward contact corridor")
			for _, segment in segments do
				for _, point in { segment.A, segment.B } do
					for _, v in point do
						assert(v == v and math.abs(v) < 20)
					end
				end
			end
		end
		equal(Sweep.distance({ x = 3, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }, { x = 0, y = 0, z = 0 }), 3)
	end)
	test("source animation library has thirty named clips with R15 joint poses and active markers", function()
		local library = R.deserializeModel(fs.readFile("assets/ascension/animations/SourceClips.rbxmx"))[1]
		equal(#library:GetChildren(), 30)
		local heavy = library:FindFirstChild("Heavy")
		assert(heavy and heavy:IsA("KeyframeSequence"))
		local markers = {}
		for _, item in heavy:GetDescendants() do
			if item:IsA("KeyframeMarker") then
				markers[item.Name] = true
			end
		end
		assert(markers.TrailOn and markers.TrailOff and markers.HitStart and markers.HitEnd)
	end)
	test("source rig has fifteen Motor6Ds and blade endpoints, with no scripts", function()
		local rig = R.deserializeModel(fs.readFile("assets/ascension/R15CollisionProxy.rbxmx"))[1]
		local joints = 0
		for _, obj in rig:GetDescendants() do
			if obj:IsA("Motor6D") then
				joints += 1
				assert(obj.Part0 and obj.Part1)
			end
			assert(not obj:IsA("LuaSourceContainer"))
		end
		equal(joints, 15)
		assert(rig.RelicBladeProxy.BladeBase and rig.RelicBladeProxy.BladeTip)
	end)
end
