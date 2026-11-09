--!strict
return function(test, equal)
	local fs = require("@lune/fs")
	local luau = require("@lune/luau")
	local R = require("@lune/roblox")
	local Traversal = require("../../src/shared/Ascension/Traversal")
	local function fixture()
		local objects, delayed, events = {}, {}, {}
		local instance = {
			new = function(class)
				local value = { ClassName = class, Destroyed = false }
				function value:Destroy()
					self.Destroyed = true
					self.Parent = nil
				end
				table.insert(objects, value)
				return value
			end,
		}
		local root = {
			Position = R.Vector3.new(0, 4, 0),
			Size = R.Vector3.new(2, 2, 1),
			CFrame = R.CFrame.identity,
			AssemblyMass = 10,
			AssemblyLinearVelocity = R.Vector3.new(0, -24, 0),
			Parent = true,
			Owner = "player",
		}
		function root:SetNetworkOwner(owner)
			self.Owner = owner
		end
		function root:SetNetworkOwnershipAuto()
			self.Owner = "auto"
		end
		local hum = { HipHeight = 2, AutoRotate = true, WalkSpeed = 17, ChangeState = function() end }
		local player = {
			Character = {
				Humanoid = hum,
				FindFirstChildOfClass = function()
					return hum
				end,
			},
		}
		local wall = {
			Anchored = true,
			IsA = function(_, name)
				return name == "BasePart"
			end,
		}
		local world = { Blocked = false, Grounded = true, Wall = false }
		function world:Blockcast()
			return if self.Blocked then { Instance = wall } else nil
		end
		function world:Raycast(_, direction)
			if direction.Y < -1 then
				return if self.Grounded then { Normal = R.Vector3.yAxis, Instance = wall } else nil
			end
			return if self.Wall then { Normal = -R.Vector3.xAxis, Instance = wall } else nil
		end
		local env = {
			Vector3 = R.Vector3,
			Vector2 = R.Vector2,
			Enum = R.Enum,
			Instance = instance,
			RaycastParams = {
				new = function()
					return {}
				end,
			},
			task = {
				delay = function(_, fn)
					table.insert(delayed, fn)
				end,
			},
			game = {
				GetService = function()
					return { Shared = { Ascension = { Traversal = "Traversal" } } }
				end,
			},
			require = function(name)
				assert(name == "Traversal")
				return Traversal
			end,
		}
		local module = luau.load(
			fs.readFile("src/server/Ascension/MovementService.luau"),
			{ environment = env, injectGlobals = true }
		)()
		local service = module.new(world, function(_, action)
			table.insert(events, action)
		end)
		return service, world, player, root, hum, objects, delayed, events, wall
	end
	test("mock movement rejects obstructed dash before creating constraints", function()
		local service, world, player, root, _, objects = fixture()
		world.Blocked = true
		assert(not service:canDash(player, root, -R.Vector3.zAxis))
		assert(not service:dash(player, root, -R.Vector3.zAxis, 1, { Distance = 18, Duration = 0.18 }))
		equal(#objects, 0)
		equal(root.Owner, "player")
	end)
	test("mock phase dash commands vertical hold and cleans force plus ownership on expiry", function()
		local service, _, player, root, hum, objects = fixture()
		assert(service:dash(player, root, -R.Vector3.zAxis, 1, { Distance = 18, Duration = 0.18 }))
		equal(hum.AutoRotate, false)
		service:step(1.09, 0.016)
		equal(service.Dashes[player].Force.VectorVelocity.Y, 0)
		assert(service.Dashes[player].Force.VectorVelocity.Z < -100)
		service:step(1.19, 0.016)
		equal(service.Dashes[player], nil)
		equal(hum.AutoRotate, true)
		equal(root.Owner, "auto")
		for _, obj in objects do
			assert(obj.Destroyed)
		end
	end)
	test("mock air jump applies one server impulse and refuses a second", function()
		local service, world, player, root, hum, _, delayed = fixture()
		root.AssemblyLinearVelocity = R.Vector3.zero
		service:observe(player, root, hum, 1)
		service:observe(player, root, hum, 1.1)
		world.Grounded = false
		service:observe(player, root, hum, 1.2)
		assert(service:airJump(player, root, hum, 1.31))
		equal(root.AssemblyLinearVelocity.Y, 48)
		assert(not service:airJump(player, root, hum, 1.6))
		for _, fn in delayed do
			fn()
		end
		equal(root.Owner, "auto")
	end)
	test("mock wall run excludes moving surfaces, caps steps and restores ownership", function()
		local service, world, player, root, hum, objects, _, events, wall = fixture()
		root.AssemblyLinearVelocity = R.Vector3.zero
		service:observe(player, root, hum, 1)
		service:observe(player, root, hum, 1.1)
		world.Grounded = false
		world.Wall = true
		service:observe(player, root, hum, 1.2)
		wall.Anchored = false
		assert(not service:wall(player, root, hum, -R.Vector3.zAxis, 1.4, 100))
		wall.Anchored = true
		assert(service:wall(player, root, hum, -R.Vector3.zAxis, 1.4, 100))
		for i = 0, 4 do
			service:step(1.471 + i * 0.14, 0.016)
		end
		service:step(2.11, 0.016)
		equal(service.Walls[player], nil)
		equal(root.Owner, "auto")
		local steps = 0
		for _, event in events do
			if event == "wallstep" then
				steps += 1
			end
		end
		equal(steps, 5)
		for _, obj in objects do
			assert(obj.Destroyed)
		end
	end)
	test("mock traversal removal is idempotent and leaves no active force or air budget", function()
		local service, _, player, root, _, objects = fixture()
		service:dash(player, root, -R.Vector3.zAxis, 1, { Distance = 18, Duration = 0.18 })
		service:airState(player)
		service:remove(player)
		service:remove(player)
		equal(service.Dashes[player], nil)
		equal(service.Walls[player], nil)
		equal(service.Air[player], nil)
		for _, obj in objects do
			assert(obj.Destroyed)
		end
	end)
end
