--!strict
local World = {}
local function part(parent, name, size, position, color, material)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = material or Enum.Material.WoodPlanks
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end
local function sign(parent, text, position, width)
	local anchor = part(parent, "Sign", Vector3.new(1, 1, 1), position, Color3.new())
	anchor.Transparency = 1
	anchor.CanCollide = false
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(width or 210, 70)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 100
	gui.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(20, 39, 48)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = Color3.fromRGB(255, 243, 220)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 16
	label.TextWrapped = true
	label.Text = text
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
	return label
end
local function prompt(p, action, object)
	local pr = Instance.new("ProximityPrompt")
	pr.ActionText = action
	pr.ObjectText = object
	pr.HoldDuration = 0.45
	pr.MaxActivationDistance = 10
	pr.RequiresLineOfSight = false
	pr.Parent = p
	return pr
end
function World.build(config)
	local folder = Instance.new("Folder")
	folder.Name = "HarborlightWorld"
	folder.Parent = workspace
	local wood = Color3.fromRGB(139, 105, 75)
	local teal = Color3.fromRGB(69, 147, 147)
	local gold = Color3.fromRGB(255, 192, 99)
	local water = part(
		folder,
		"Sea",
		Vector3.new(600, 1, 600),
		Vector3.new(0, -5, 0),
		Color3.fromRGB(31, 91, 121),
		Enum.Material.SmoothPlastic
	)
	water.CanCollide = false
	for x = -48, 48, 8 do
		part(folder, "Boardwalk", Vector3.new(7.7, 0.2, 16), Vector3.new(x, 0.15, 8), wood)
	end
	for _, x in { -53, 53 } do
		part(folder, "SeaWall", Vector3.new(1, 3, 88), Vector3.new(x, 1, 0), wood)
	end
	for _, z in { -43, 43 } do
		part(folder, "SeaWall", Vector3.new(106, 3, 1), Vector3.new(0, 1, z), wood)
	end
	sign(folder, "HARBORLIGHT\nRestore together", Vector3.new(0, 10, 18), 300)
	sign(
		folder,
		"1. Recover supplies at crates\n2. Contribute to the glowing repair",
		Vector3.new(0, 5, 24),
		270
	)
	local supplies = {}
	for i, pos in
		{
			Vector3.new(-40, 2, 22),
			Vector3.new(-40, 2, 0),
			Vector3.new(40, 2, 0),
			Vector3.new(40, 2, 22),
			Vector3.new(-16, 2, 15),
			Vector3.new(16, 2, 15),
			Vector3.new(-40, 2, -25),
			Vector3.new(40, 2, -25),
		}
	do
		local p = part(folder, "Supply" .. i, Vector3.new(3, 3, 3), pos, teal)
		part(folder, "CrateBand", Vector3.new(3.1, 0.4, 3.1), pos, gold)
		supplies[i] = { Part = p, Prompt = prompt(p, "Recover supply", "Harbor supplies"), AvailableAt = 0 }
	end
	local projects = {}
	for i, pos in { Vector3.new(-28, 2, -10), Vector3.new(0, 2, -10), Vector3.new(28, 2, -10) } do
		local station = part(folder, "RepairStation" .. i, Vector3.new(6, 3, 4), pos, gold)
		projects[i] = {
			Part = station,
			Prompt = prompt(station, "Contribute supplies", config.Projects[i].Name),
			Label = sign(folder, config.Projects[i].Name, pos + Vector3.new(0, 5, 0), 200),
			Pieces = {},
		}
	end
	local pier = projects[1].Pieces
	for i = 1, 5 do
		table.insert(
			pier,
			part(folder, "PierSegment", Vector3.new(10, 0.5, 3.4), Vector3.new(-28, 1, -17 - i * 3.5), wood)
		)
	end
	local greenhouse = projects[2].Pieces
	for _, x in { -5, 5 } do
		table.insert(
			greenhouse,
			part(
				folder,
				"GreenhouseWall",
				Vector3.new(0.5, 10, 13),
				Vector3.new(x, 5, -26),
				teal,
				Enum.Material.Glass
			)
		)
	end
	table.insert(
		greenhouse,
		part(
			folder,
			"GreenhouseRoof",
			Vector3.new(11, 0.5, 14),
			Vector3.new(0, 10, -26),
			teal,
			Enum.Material.Glass
		)
	)
	for _, x in { -3, 0, 3 } do
		table.insert(
			greenhouse,
			part(
				folder,
				"Planter",
				Vector3.new(2, 3, 9),
				Vector3.new(x, 1.5, -26),
				Color3.fromRGB(93, 153, 99),
				Enum.Material.Grass
			)
		)
	end
	local beacon = projects[3].Pieces
	table.insert(
		beacon,
		part(
			folder,
			"BeaconTower",
			Vector3.new(7, 20, 7),
			Vector3.new(28, 10, -26),
			Color3.fromRGB(235, 225, 205),
			Enum.Material.Brick
		)
	)
	local lamp =
		part(folder, "BeaconLamp", Vector3.new(8, 3, 8), Vector3.new(28, 22, -26), gold, Enum.Material.Neon)
	table.insert(beacon, lamp)
	local light = Instance.new("PointLight")
	light.Color = gold
	light.Range = 35
	light.Brightness = 2
	light.Parent = lamp
	local garden = part(
		folder,
		"Garden",
		Vector3.new(16, 0.3, 12),
		Vector3.new(35, 0.3, 34),
		Color3.fromRGB(87, 137, 93),
		Enum.Material.Grass
	)
	local bench = part(folder, "ReadingBench", Vector3.new(8, 1, 2), Vector3.new(35, 2, 36), wood)
	garden.CanCollide = true
	sign(folder, "Garden of Hope\nOptional Christian reading · No rewards", Vector3.new(35, 7, 33), 245)
	local reading = prompt(bench, "Read · optional", "Christian teaching about Jesus")
	-- Reading is handled locally; no server listener, profile field or analytics path.
	reading.Name = "ChristianReading"
	return { Folder = folder, Supplies = supplies, Projects = projects, Light = light }
end
function World.render(world, state, config)
	for i, project in world.Projects do
		local complete = i < state.Index
		local active = i == state.Index and not state.Complete
		project.Prompt.Enabled = active
		project.Part.Color = if active then Color3.fromRGB(255, 195, 100) else Color3.fromRGB(90, 112, 115)
		project.Label.Text = config.Projects[i].Name
			.. (
				if complete
					then "\nRESTORED"
					elseif active then string.format(
						"\n%d / %d supplies",
						state.Progress,
						config.Projects[i].Required
					)
					else "\nNext in the restoration route"
			)
		for _, piece in project.Pieces do
			piece.Transparency = if complete
				then (if piece.Material == Enum.Material.Glass then 0.35 else 0)
				else 0.82
			piece.CanCollide = complete
		end
	end
	world.Light.Enabled = state.Complete
end
return World
