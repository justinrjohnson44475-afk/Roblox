--!strict
-- This exact builder is run in Cloud to bake assets/world.rbxmx, then used for engine binding.
local World = {}
local function rgb(c)
	return Color3.fromRGB(c[1], c[2], c[3])
end
local function part(parent, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Anchored = true
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end
local function cylinder(parent, name, radius, height, pos, color, material)
	return part(
		parent,
		name,
		Vector3.new(height, radius * 2, radius * 2),
		CFrame.new(pos) * CFrame.Angles(0, 0, math.pi / 2),
		color,
		material,
		Enum.PartType.Cylinder
	)
end
local function ring(parent, name, radius, pos, color, width, count)
	for i = 1, count or 24 do
		local a = i * math.pi * 2 / (count or 24)
		local point = pos + Vector3.new(math.cos(a) * radius, 0, math.sin(a) * radius)
		part(
			parent,
			name,
			Vector3.new(width or 1, 0.25, radius * 0.28),
			CFrame.new(point) * CFrame.Angles(0, -a, 0),
			color,
			Enum.Material.Neon
		)
	end
end
local function label(p, text, width)
	local gui = Instance.new("BillboardGui")
	gui.Name = "WorldLabel"
	gui.Size = UDim2.fromOffset(width or 170, 48)
	gui.StudsOffset = Vector3.new(0, 4, 0)
	gui.MaxDistance = 65
	gui.AlwaysOnTop = false
	gui.Parent = p
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 14
	l.TextColor3 = Color3.fromRGB(235, 246, 251)
	l.TextStrokeTransparency = 0.4
	l.TextWrapped = true
	l.Text = text
	l.Parent = gui
end
local function prompt(p, action, object)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.KeyboardKeyCode = Enum.KeyCode.F
	pr.GamepadKeyCode = Enum.KeyCode.ButtonL1
	pr.ObjectText = object
	pr.MaxActivationDistance = 11
	pr.HoldDuration = 0.2
	pr.RequiresLineOfSight = false
	pr.Parent = p
	return pr
end
local function crystal(parent, pos, scale, color, rotation)
	part(
		parent,
		"RelicCrystal",
		Vector3.new(2, 5, 2) * scale,
		CFrame.new(pos) * CFrame.Angles(0.18, rotation or 0, 0.3) * CFrame.Angles(0, 0, math.pi / 4),
		color,
		Enum.Material.Neon
	)
end
local function tree(parent, pos, scale, color, seed)
	local bark = Color3.fromRGB(65, 57, 59)
	part(
		parent,
		"AncientTrunk",
		Vector3.new(1.5, 10, 1.5) * scale,
		CFrame.new(pos + Vector3.new(0, 4.5 * scale, 0)) * CFrame.Angles(0, seed, -0.08),
		bark,
		Enum.Material.Wood
	)
	for j = 0, 2 do
		part(
			parent,
			"Canopy",
			Vector3.new(10 - j * 2, 4, 9 - j) * scale,
			CFrame.new(pos + Vector3.new(j * 0.5, (9 + j * 2) * scale, 0))
				* CFrame.Angles(0.1, seed + j * 0.7, 0.07),
			color,
			Enum.Material.Grass
		)
	end
end
local function ruins(parent, center, radius, color, y)
	for i = 1, 7 do
		local a = i / 7 * math.pi * 2
		local height = 8 + (i % 3) * 4
		local pos = center + Vector3.new(math.cos(a) * radius, height / 2 + y, math.sin(a) * radius)
		part(
			parent,
			"BrokenPillar",
			Vector3.new(3.5, height, 3.5),
			CFrame.new(pos) * CFrame.Angles(0, -a, if i % 2 == 0 then 0.05 else -0.06),
			color,
			Enum.Material.Marble
		)
		part(
			parent,
			"PillarCrown",
			Vector3.new(5, 1, 5),
			CFrame.new(pos + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, -a, 0),
			color,
			Enum.Material.Marble
		)
	end
end
function World.build(config)
	local root = Instance.new("Folder")
	root.Name = "RiftwakeWorld"
	local stone = Color3.fromRGB(56, 66, 85)
	local ivory = Color3.fromRGB(215, 221, 209)
	local dark = Color3.fromRGB(28, 35, 52)
	local gold = Color3.fromRGB(255, 183, 87)
	for _, region in config.Regions do
		local f = Instance.new("Folder")
		f.Name = region.Id
		f.Parent = root
		local c = Vector3.new(unpack(region.Center))
		local accent = rgb(region.Color)
		local radius = region.Radius
		cylinder(f, "IslandBedrock", radius, 8, c - Vector3.new(0, 4, 0), stone, Enum.Material.Slate)
		cylinder(
			f,
			"Ground",
			radius - 1,
			1,
			c,
			if region.Id == "ember"
				then Color3.fromRGB(81, 58, 61)
				elseif region.Id == "astral" then Color3.fromRGB(82, 80, 115)
				else Color3.fromRGB(80, 119, 112),
			Enum.Material.Slate
		)
		for i = 1, 11 do
			local a = i / 11 * math.pi * 2
			local r = radius * 0.82
			local rock = c + Vector3.new(math.cos(a) * r, -10 - (i % 3) * 3, math.sin(a) * r)
			part(
				f,
				"FloatingCliff",
				Vector3.new(22, 18, 21),
				CFrame.new(rock) * CFrame.Angles(i * 0.13, a, 0.18),
				stone,
				Enum.Material.Rock
			)
			if i % 2 == 0 then
				crystal(f, rock - Vector3.new(0, 10, 0), 1.6, accent, a)
			end
		end
		cylinder(f, "ArrivalTerrace", 14, 1.2, c + Vector3.new(0, 0.9, 34), ivory, Enum.Material.Marble)
		ring(f, "ArrivalInlay", 11, c + Vector3.new(0, 1.55, 34), accent, 0.6)
		for i = 1, 9 do
			local x = (i % 3 - 1) * 4.3
			local z = 28 - math.floor((i - 1) / 3) * 7
			part(
				f,
				"Waystone",
				Vector3.new(4, 0.5, 5),
				CFrame.new(c + Vector3.new(x, 0.8, z)),
				ivory,
				Enum.Material.Marble
			)
		end
		if region.Id ~= "hub" then
			cylinder(f, "WardenArena", 22, 1, c + Vector3.new(0, 0.5, -31), dark, Enum.Material.Basalt)
			ring(f, "WardenSeal", 20, c + Vector3.new(0, 1.1, -31), accent, 0.8)
			ruins(f, c + Vector3.new(0, 0, -31), 24, ivory, 0)
			local back = part(
				f,
				"ReturnGate",
				Vector3.new(5, 1, 5),
				CFrame.new(c + Vector3.new(0, 2, 42)),
				accent,
				Enum.Material.Neon
			)
			back:SetAttribute("Destination", "hub")
			prompt(back, "Return to sanctuary", "Dawn gate")
			for i = 1, 7 do
				local side = if i % 2 == 0 then -1 else 1
				local pos = c + Vector3.new(side * (37 + i % 3 * 4), 1, -39 + i * 11)
				if region.Id == "verdant" then
					tree(f, pos, 0.8 + (i % 3) * 0.2, Color3.fromRGB(80 + i * 3, 157, 134), i)
				elseif region.Id == "ember" then
					part(
						f,
						"ObsidianSpire",
						Vector3.new(5, 16 + i, 5),
						CFrame.new(pos + Vector3.new(0, 6, 0)) * CFrame.Angles(0.15, i, 0.22),
						Color3.fromRGB(42, 35, 46),
						Enum.Material.Basalt
					)
					crystal(f, pos + Vector3.new(0, 3, 0), 1.2, accent, i)
				else
					crystal(f, pos + Vector3.new(0, 5, 0), 2.2, accent, i)
				end
			end
			for i = 1, 4 do
				local pos = c + Vector3.new(if i % 2 == 0 then 31 else -31, 0.8, i * 10 - 18)
				part(
					f,
					"RuinedWall",
					Vector3.new(2, 5 + i, 10),
					CFrame.new(pos + Vector3.new(0, 3, 0)) * CFrame.Angles(0, i * 0.35, 0),
					ivory,
					Enum.Material.Marble
				)
			end
		else
			cylinder(f, "SanctuaryCourt", 34, 1, c + Vector3.new(0, 0.65, 0), ivory, Enum.Material.Marble)
			ring(f, "CourtInlay", 30, c + Vector3.new(0, 1.3, 0), rgb({ 92, 225, 218 }), 0.5)
			cylinder(f, "ForgePlinth", 9, 2, Vector3.new(0, 2, 0), dark, Enum.Material.Basalt)
			cylinder(f, "ForgeCore", 5, 1, Vector3.new(0, 3.3, 0), gold, Enum.Material.Neon)
			local forge =
				part(f, "ForgeStation", Vector3.new(6, 3, 4), CFrame.new(0, 5, 0), dark, Enum.Material.Metal)
			label(forge, "RELIC FORGE\nUpgrade · Evolve · Choose a path")
			prompt(forge, "Open forge", "Shape your ascension")
			crystal(f, Vector3.new(0, 11, 0), 1.8, gold, 0.4)
			for i = 1, 4 do
				local a = i * math.pi / 2 + math.pi / 4
				local pos = Vector3.new(math.cos(a) * 9, 9, math.sin(a) * 9)
				part(
					f,
					"ForgeArch",
					Vector3.new(2, 16, 2),
					CFrame.new(pos) * CFrame.Angles(0.1, a, 0.15),
					ivory,
					Enum.Material.Marble
				)
			end
			for i = 2, #config.Regions do
				local target = config.Regions[i]
				local pos = if i == 2
					then Vector3.new(-30, 1.6, 4)
					elseif i == 3 then Vector3.new(30, 1.6, 4)
					else Vector3.new(0, 1.6, -31)
				local color = rgb(target.Color)
				local gate = cylinder(f, "Gate_" .. target.Id, 6, 0.7, pos, color, Enum.Material.Neon)
				gate:SetAttribute("Destination", target.Id)
				for _, side in { -1, 1 } do
					part(
						f,
						"GatePillar",
						Vector3.new(2.5, 13, 3),
						CFrame.new(pos + Vector3.new(side * 6, 6, 0)),
						ivory,
						Enum.Material.Marble
					)
				end
				part(
					f,
					"GateLintel",
					Vector3.new(15, 2, 4),
					CFrame.new(pos + Vector3.new(0, 13, 0)),
					ivory,
					Enum.Material.Marble
				)
				local veil = part(
					f,
					"GateVeil",
					Vector3.new(9, 10, 0.35),
					CFrame.new(pos + Vector3.new(0, 5.5, 0)),
					color,
					Enum.Material.Neon
				)
				veil.Transparency = 0.65
				veil.CanCollide = false
				label(gate, target.Name .. "\nLv." .. target.Level)
				prompt(gate, "Enter region", target.Name)
			end
			for i = 1, 8 do
				local a = i * math.pi / 4
				tree(
					f,
					Vector3.new(math.cos(a) * 46, 0.5, math.sin(a) * 46),
					0.9,
					Color3.fromRGB(96, 154, 149),
					a
				)
			end
			local bench = part(
				f,
				"ReadingBench",
				Vector3.new(7, 1, 2),
				CFrame.new(30, 2, 36),
				ivory,
				Enum.Material.Marble
			)
			label(bench, "Garden of Hope\nOptional Christian reading · No rewards", 210)
			prompt(bench, "Read · optional", "Christian teaching about Jesus").Name = "ChristianReading"
		end
	end
	-- Break the platform silhouettes and give each destination its own landmark/composition.
	for _, region in config.Regions do
		local f = root[region.Id]
		local c = Vector3.new(unpack(region.Center))
		local accent = rgb(region.Color)
		local earth = if region.Id == "verdant"
			then Color3.fromRGB(67, 108, 93)
			elseif region.Id == "ember" then Color3.fromRGB(68, 48, 57)
			elseif region.Id == "astral" then Color3.fromRGB(62, 65, 99)
			else Color3.fromRGB(75, 106, 109)
		for i = 1, 12 do
			local a = i / 12 * math.pi * 2
			local r = region.Radius - 7 + (i % 3) * 2
			local p = c + Vector3.new(math.cos(a) * r, 0.2 + (i % 3) * 0.3, math.sin(a) * r)
			part(
				f,
				"RaggedTerrain",
				Vector3.new(18 + i % 4 * 3, 2.5, 17 + i % 3 * 3),
				CFrame.new(p) * CFrame.Angles(0, a * 0.7, 0.01),
				earth,
				Enum.Material.Slate
			)
			if i % 3 == 0 then
				part(
					f,
					"CliffTooth",
					Vector3.new(13, 20, 12),
					CFrame.new(p - Vector3.new(0, 19, 0)) * CFrame.Angles(0.1, a, 0.6),
					stone,
					Enum.Material.Rock
				)
			end
		end
		if region.Id == "verdant" then
			-- Water/light on one side, a broken grove arch on the other: readable silhouettes.
			for i = 1, 5 do
				local pos = c + Vector3.new(-24 - i * 5, 0.8, 12 + math.sin(i) * 5)
				local stream = part(
					f,
					"SpringChannel",
					Vector3.new(9, 0.18, 3.5),
					CFrame.new(pos) * CFrame.Angles(0, 0.35 * math.sin(i), 0),
					Color3.fromRGB(44, 157, 170),
					Enum.Material.Glass
				)
				stream.CanCollide = false
				stream.Transparency = 0.18
			end
			for i = 1, 3 do
				local fall = part(
					f,
					"Skyfall",
					Vector3.new(3 + i, 40 + i * 5, 1.2),
					CFrame.new(c + Vector3.new(-62, -20 - i * 2, 8 + i * 5)),
					Color3.fromRGB(73, 185, 198),
					Enum.Material.Glass
				)
				fall.Transparency = 0.35
				fall.CanCollide = false
			end
			for _, side in { -1, 1 } do
				part(
					f,
					"GroveArchBase",
					Vector3.new(5, 18, 5),
					CFrame.new(c + Vector3.new(side * 8, 9, -3)),
					ivory,
					Enum.Material.Marble
				)
				part(
					f,
					"GroveArchShoulder",
					Vector3.new(5, 12, 5),
					CFrame.new(c + Vector3.new(side * 6, 20, -3)) * CFrame.Angles(0, 0, side * 0.38),
					ivory,
					Enum.Material.Marble
				)
			end
			part(
				f,
				"GroveArchCrown",
				Vector3.new(7, 3, 6),
				CFrame.new(c + Vector3.new(0, 25, -3)),
				ivory,
				Enum.Material.Marble
			)
			for i = 1, 6 do
				local side = if i % 2 == 0 then 1 else -1
				tree(
					f,
					c + Vector3.new(side * (37 + i % 3 * 3), 1, -23 + i * 8),
					1.25 + i % 2 * 0.25,
					Color3.fromRGB(54, 131 + i * 2, 111),
					i
				)
			end
			for i = 1, 11 do
				local a = i * 2.4
				local pos = c + Vector3.new(math.cos(a) * (25 + i % 3 * 6), 1.6, math.sin(a) * 25)
				part(
					f,
					"GroveStone",
					Vector3.new(4 + i % 3, 2.5, 3),
					CFrame.new(pos) * CFrame.Angles(0.15, a, 0.12),
					Color3.fromRGB(107, 135, 124),
					Enum.Material.Rock
				)
			end
		elseif region.Id == "ember" then
			for _, side in { -1, 1 } do
				for i = 1, 4 do
					local pos = c + Vector3.new(side * (31 + i * 3), 0.6, -35 + i * 17)
					part(
						f,
						"CinderFissure",
						Vector3.new(2, 0.2, 22),
						CFrame.new(pos) * CFrame.Angles(0, side * 0.45 + i * 0.15, 0),
						Color3.fromRGB(244, 96, 47),
						Enum.Material.Neon
					)
					part(
						f,
						"CinderRidge",
						Vector3.new(8, 8 + i * 2, 8),
						CFrame.new(pos + Vector3.new(side * 5, 3 + i, 0))
							* CFrame.Angles(0.12, i * 0.6, side * 0.23),
						Color3.fromRGB(38, 35, 44),
						Enum.Material.Basalt
					)
				end
			end
			for i = 1, 3 do
				local pos = c + Vector3.new(-17 + i * 8, 1.6, -50)
				part(
					f,
					"FallenObelisk",
					Vector3.new(4, 22 + i * 3, 4),
					CFrame.new(pos + Vector3.new(0, 9, 0)) * CFrame.Angles(0.12, 0.25, -0.2 + i * 0.1),
					Color3.fromRGB(55, 43, 48),
					Enum.Material.Basalt
				)
				crystal(f, pos + Vector3.new(0, 23 + i * 2, 0), 0.8, accent, 0)
			end
		elseif region.Id == "astral" then
			-- Monumental broken halo is legible from the sanctuary, unlike the other regions.
			for i = 1, 17 do
				local a = i / 20 * math.pi * 2
				local pos = c + Vector3.new(math.cos(a) * 24, 27 + math.sin(a) * 24, -53)
				part(
					f,
					"BrokenStormHalo",
					Vector3.new(8, 4, 4),
					CFrame.new(pos) * CFrame.Angles(0, 0, a + math.pi / 2),
					ivory,
					Enum.Material.Marble
				)
				part(
					f,
					"HaloInlay",
					Vector3.new(4, 0.3, 4.3),
					CFrame.new(pos) * CFrame.Angles(0, 0, a + math.pi / 2),
					accent,
					Enum.Material.Neon
				)
			end
			for i = 1, 5 do
				local side = if i % 2 == 0 then -1 else 1
				local pos = c + Vector3.new(side * (30 + i * 2), 8 + i * 2, -28 + i * 11)
				part(
					f,
					"LevitatingRelic",
					Vector3.new(6, 6, 6),
					CFrame.new(pos) * CFrame.Angles(i * 0.3, i, 0.5),
					Color3.fromRGB(100, 102, 148),
					Enum.Material.Marble
				)
				crystal(f, pos + Vector3.new(0, 5, 0), 0.8, accent, i)
			end
		else
			-- Sanctuary colonnade and an oversized forge canopy make the hub a destination.
			for _, side in { -1, 1 } do
				for i = 1, 4 do
					local pos = Vector3.new(side * (34 + i * 3), 5, -21 + i * 9)
					part(
						f,
						"SanctuaryButtress",
						Vector3.new(3, 10, 3),
						CFrame.new(pos),
						ivory,
						Enum.Material.Marble
					)
					part(
						f,
						"SanctuaryLantern",
						Vector3.new(1, 2, 1),
						CFrame.new(pos + Vector3.new(0, 6, 0)),
						gold,
						Enum.Material.Neon
					)
				end
			end
			for i = 1, 4 do
				local a = i * math.pi / 2
				part(
					f,
					"ForgeCanopy",
					Vector3.new(16, 2, 4),
					CFrame.new(math.cos(a) * 5, 18, math.sin(a) * 5) * CFrame.Angles(0, -a + math.pi / 2, 0),
					ivory,
					Enum.Material.Marble
				)
			end
			crystal(f, Vector3.new(0, 23, 0), 1.4, gold, 0.5)
			for i = 1, 5 do
				part(
					f,
					"ArrivalStep",
					Vector3.new(15 + i * 2, 0.4, 3),
					CFrame.new(0, 0.8 + i * 0.08, 19 + i * 3),
					ivory,
					Enum.Material.Marble
				)
			end
		end
	end

	for _, def in config.Spawns do
		local region
		for _, r in config.Regions do
			if r.Id == def.Region then
				region = r
			end
		end
		local marker = part(
			root[def.Region],
			"Spawn_" .. def.Id,
			Vector3.new(1, 1, 1),
			CFrame.new(
				Vector3.new(unpack(region.Center)) + Vector3.new(unpack(def.Offset)) + Vector3.new(0, 4, 0)
			),
			Color3.new()
		)
		marker.Transparency = 1
		marker.CanCollide = false
		marker.CanTouch = false
		marker.CanQuery = false
	end
	return root
end
function World.region(config, id)
	for _, region in config.Regions do
		if region.Id == id then
			return region
		end
	end
	return nil
end
return World
