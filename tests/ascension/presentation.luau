--!strict
return function(test, equal)
	local fs = require("@lune/fs")
	local luau = require("@lune/luau")
	local R = require("@lune/roblox")
	local function fixture()
		local noEvent = { Connect = function() end }
		local shared = { Ascension = { AttackDefinitions = "definitions", Traversal = "traversal" } }
		local services = {
			RunService = { PreAnimation = noEvent, PreSimulation = noEvent },
			Players = {},
			ReplicatedStorage = { Shared = shared },
		}
		local values = {
			definitions = require("../../src/shared/Ascension/AttackDefinitions"),
			traversal = require("../../src/shared/Ascension/Traversal"),
		}
		local env = {
			game = {
				GetService = function(_, name)
					return services[name]
				end,
			},
			require = function(name)
				return values[name]
			end,
			CFrame = R.CFrame,
			workspace = {
				GetServerTimeNow = function()
					return 10
				end,
			},
		}
		local module = luau.load(
			fs.readFile("src/client/Ascension/MotionController.luau"),
			{ environment = env, injectGlobals = true }
		)()
		local plays, stops = 0, 0
		local track = {
			Stop = function()
				stops += 1
			end,
			AdjustSpeed = function() end,
		}
		local animations = {
			play = function()
				plays += 1
				return track
			end,
		}
		local motion = module.new({ UserId = 99 }, animations, {}, function()
			return 1
		end)
		motion.Model = {}
		return motion, track, function()
			return plays, stops
		end
	end
	test("accepted strike prediction continues instead of stopping on confirmation", function()
		local motion, track, counts = fixture()
		motion.Predicted[4] = { Name = "Light1", Track = track, At = 9.95, Expires = 10.8, Attack = true }
		motion:event({
			actor = 99,
			result = "attack",
			action = "Light1",
			sequence = 4,
			timestamp = 9.99,
			ends = 10.42,
		})
		local plays, stops = counts()
		equal(plays, 0)
		equal(stops, 0)
		assert(motion.Predicted[4].Confirmed)
		equal(motion.BusyUntil, 10.42)
	end)
	test("rejected prediction stops its track and clears queued attack and air claim", function()
		local motion, track, counts = fixture()
		motion.AirUsed = true
		motion.Queue = { Action = "light", Expires = 11 }
		motion.BusyUntil = 11
		motion.Predicted[7] =
			{ Name = "DoubleJump", Track = track, At = 9.95, Expires = 10.8, Air = true, Attack = true }
		motion:reject({ sequence = 7 })
		local _, stops = counts()
		equal(stops, 1)
		equal(motion.Queue, nil)
		equal(motion.BusyUntil, 10)
		equal(motion.AirUsed, false)
		equal(motion.Predicted[7], nil)
	end)
	test("locked and unaffordable E/R never predict a fidget animation", function()
		local motion, _, counts = fixture()
		motion.State = { profile = { Level = 1 }, abilityLevel = 1, focus = 100, encounter = {} }
		motion:attack("burst")
		motion:attack("overdrive")
		local plays = counts()
		equal(plays, 0)
		equal(next(motion.Predicted), nil)
		motion.State.abilityLevel = 5
		motion.State.focus = 0
		motion:attack("burst")
		motion:attack("overdrive")
		plays = counts()
		equal(plays, 0)
	end)
	test("ready Coreburst predicts while a cooling ability stays still", function()
		local motion, _, counts = fixture()
		motion.State = {
			profile = { Level = 5 },
			abilityLevel = 5,
			focus = 100,
			encounter = {},
			cooldowns = {
				burst = 1,
			},
		}
		motion:attack("burst")
		equal(counts(), 0)
		motion.State.cooldowns.burst = 0
		motion:attack("burst")
		equal(counts(), 1)
		assert(motion.Predicted[1])
	end)
end
