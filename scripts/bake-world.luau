--!strict
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
local config = require("../src/shared/Config")
local env = table.clone(roblox)
local World = luau.load(fs.readFile("src/server/World.luau"), { environment = env, injectGlobals = true })()
local world = World.build(config)
fs.writeFile("assets/world.rbxmx", roblox.serializeModel({ world }, true))
fs.writeDir("build")
local geometry = {}
local function export(root, category)
	for _, p in root:GetDescendants() do
		if p:IsA("BasePart") and p.Transparency < 1 then
			table.insert(geometry, {
				name = p.Name,
				category = category,
				size = { p.Size.X, p.Size.Y, p.Size.Z },
				cf = { p.CFrame:GetComponents() },
				color = { p.Color.R, p.Color.G, p.Color.B },
				material = p.Material.Name,
				shape = if p:IsA("Part") then p.Shape.Name else "Block",
				alpha = 1 - p.Transparency,
			})
		end
	end
end
export(world, "world")
local Appearance =
	luau.load(fs.readFile("src/server/Appearance.luau"), { environment = env, injectGlobals = true })()
for _, region in config.Regions do
	if region.Boss then
		local def = config.Enemies[region.Boss]
		local model = Appearance.enemy(def, roblox.Color3.fromRGB(unpack(region.Color)))
		local offset = roblox.CFrame.new(
			roblox.Vector3.new(unpack(region.Center)) + roblox.Vector3.new(0, def.Scale * 3.4 + 1, -32)
		)
		for _, p in model:GetDescendants() do
			if p:IsA("BasePart") then
				p.CFrame = offset * roblox.CFrame.Angles(0, math.pi, 0) * p.CFrame
			end
		end
		export(model, "enemy")
	end
end
print(
	string.format(
		"Baked authored world and exported %d visible parts. Not a Roblox engine render.",
		#geometry
	)
)
local forms = {}
for form = 0, 3 do
	local character = roblox.Instance.new("Model")
	character.Name = "FormPreview" .. form
	local offset = roblox.Vector3.new((form - 1.5) * 6, 0, 0)
	local function body(name, size, pos, color)
		local p = roblox.Instance.new("Part")
		p.Name = name
		p.Size = size
		p.CFrame = roblox.CFrame.new(pos + offset)
		p.Anchored = true
		p.Color = color
		p.Parent = character
		return p
	end
	local cloth = roblox.Color3.fromRGB(32, 46, 68)
	body("Torso", roblox.Vector3.new(2, 2, 1), roblox.Vector3.new(0, 3, 0), cloth)
	body("Right Arm", roblox.Vector3.new(1, 2, 1), roblox.Vector3.new(1.5, 3, 0), cloth)
	body("Left Arm", roblox.Vector3.new(1, 2, 1), roblox.Vector3.new(-1.5, 3, 0), cloth)
	body(
		"Head",
		roblox.Vector3.new(1.3, 1.3, 1.3),
		roblox.Vector3.new(0, 4.7, 0),
		roblox.Color3.fromRGB(192, 180, 159)
	)
	body("Left Leg", roblox.Vector3.new(0.9, 2, 1), roblox.Vector3.new(-0.55, 1, 0), cloth)
	body("Right Leg", roblox.Vector3.new(0.9, 2, 1), roblox.Vector3.new(0.55, 1, 0), cloth)
	Appearance.rig(character, form, roblox.Color3.fromRGB(95, 230, 213), false)
	for _, p in character:GetDescendants() do
		if p:IsA("BasePart") then
			table.insert(forms, {
				name = p.Name,
				category = "form" .. form,
				size = { p.Size.X, p.Size.Y, p.Size.Z },
				cf = { p.CFrame:GetComponents() },
				color = { p.Color.R, p.Color.G, p.Color.B },
				material = p.Material.Name,
				shape = p.Shape.Name,
				alpha = 1,
			})
		end
	end
	if form == 1 then
		for _, p in character:GetDescendants() do
			if p:IsA("BasePart") then
				p.CFrame = roblox.CFrame.new(-162, 6.5, -10) * p.CFrame
			end
		end
		export(character, "preview-avatar")
	end
end
fs.writeFile("build/rig-geometry.json", serde.encode("json", forms))

fs.writeFile("build/world-geometry.json", serde.encode("json", geometry))
