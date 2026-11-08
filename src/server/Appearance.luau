--!strict
local Appearance = {}
local function piece(parent, name, size, cf, color, material, anchored, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.Metal
	p.Anchored = anchored == true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Massless = true
	if shape then
		p.Shape = shape
	end
	p.Parent = parent
	return p
end
local function join(parent, base, part)
	local w = Instance.new("WeldConstraint")
	w.Part0 = base
	w.Part1 = part
	w.Parent = parent
end
function Appearance.rig(character, form, color, supporter)
	local old = character:FindFirstChild("RelicRig")
	if old then
		old:Destroy()
	end
	local hand = character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm")
	local torso = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso")
	if not hand or not torso then
		return
	end
	local model = Instance.new("Model")
	model.Name = "RelicRig"
	model.Parent = character
	local base = piece(
		model,
		"Gauntlet",
		Vector3.new(1.15 + form * 0.14, 1.2, 1.4 + form * 0.22),
		hand.CFrame * CFrame.new(0, -0.2, -0.2),
		Color3.fromRGB(32, 45, 65)
	)
	local motor = Instance.new("Motor6D")
	motor.Name = "StrikeJoint"
	motor.Part0 = hand
	motor.Part1 = base
	motor.C0 = CFrame.new(0, -0.2, -0.2)
	motor.Parent = base
	local core = piece(
		model,
		"GauntletCore",
		Vector3.new(0.5 + form * 0.13, 0.5, 0.65),
		base.CFrame * CFrame.new(0, 0, -0.72 - form * 0.1),
		color,
		Enum.Material.Neon
	)
	join(core, base, core)
	for i = 1, form + 1 do
		local blade = piece(
			model,
			"RigBlade",
			Vector3.new(0.2, 0.4, 1.6 + form * 0.4),
			base.CFrame * CFrame.new((i - (form + 2) / 2) * 0.4, 0.55, -0.8),
			color,
			Enum.Material.Neon
		)
		join(blade, base, blade)
	end
	if form >= 1 then
		local plate = piece(
			model,
			"Breastplate",
			Vector3.new(1.9, 1.65, 0.25),
			torso.CFrame * CFrame.new(0, 0.1, -0.62),
			Color3.fromRGB(125, 148, 163)
		)
		join(plate, torso, plate)
		local heart = piece(
			model,
			"RigSigil",
			Vector3.new(0.45, 0.6, 0.18),
			torso.CFrame * CFrame.new(0, 0.2, -0.82) * CFrame.Angles(0, 0, 0.5),
			color,
			Enum.Material.Neon
		)
		join(heart, torso, heart)
		for _, side in { -1, 1 } do
			local shoulder = piece(
				model,
				"ShoulderPlate",
				Vector3.new(1.2, 0.75, 1.8),
				torso.CFrame * CFrame.new(side * 1.25, 0.75, 0) * CFrame.Angles(0, 0, side * -0.2),
				Color3.fromRGB(207, 213, 217)
			)
			join(shoulder, torso, shoulder)
		end
	end
	if form >= 2 then
		for _, side in { -1, 1 } do
			local fin = piece(
				model,
				"OrbitBlade",
				Vector3.new(0.4, 3.4 + form * 0.3, 0.8),
				torso.CFrame * CFrame.new(side * 1.9, 0.4, 0.9) * CFrame.Angles(0.1, 0, side * -0.35),
				color,
				Enum.Material.Neon
			)
			join(fin, torso, fin)
		end
	end
	if form >= 3 then
		for i = 1, 7 do
			local angle = (i - 1) / 6 * math.pi
			local crown = piece(
				model,
				"CrownSigil",
				Vector3.new(0.45, 0.8, 0.22),
				torso.CFrame
					* CFrame.new(math.cos(angle) * 1.25, 2.4 + math.sin(angle) * 0.9, 0.25)
					* CFrame.Angles(0, 0, angle - math.pi / 2),
				color,
				Enum.Material.Neon
			)
			join(crown, torso, crown)
		end
	end
	if supporter then
		local trim = piece(
			model,
			"OceanTrim",
			Vector3.new(1.3, 0.12, 1.5),
			base.CFrame,
			Color3.fromRGB(90, 172, 255),
			Enum.Material.Neon
		)
		join(trim, base, trim)
	end
	return model
end
function Appearance.enemy(def, color)
	local model = Instance.new("Model")
	model.Name = def.Name
	local scale = def.Scale
	local root = piece(
		model,
		"Core",
		Vector3.new(2.6, 3.4, 2.3) * scale,
		CFrame.new(),
		Color3.fromRGB(40, 49, 65),
		Enum.Material.Slate,
		true
	)
	model.PrimaryPart = root
	local center = piece(
		model,
		"ExposedCore",
		Vector3.new(1.1, 1.1, 1) * scale,
		CFrame.new(0, 0.2 * scale, -1.1 * scale),
		color,
		Enum.Material.Neon,
		true,
		Enum.PartType.Ball
	)
	for _, side in { -1, 1 } do
		piece(
			model,
			"Shoulder",
			Vector3.new(1.2, 1.3, 1.8) * scale,
			CFrame.new(side * 2 * scale, 0.8 * scale, 0) * CFrame.Angles(0, 0, side * -0.3),
			Color3.fromRGB(165, 181, 183),
			Enum.Material.Metal,
			true
		)
		piece(
			model,
			"Arm",
			Vector3.new(0.9, 2, 1) * scale,
			CFrame.new(side * 2.2 * scale, -0.9 * scale, 0),
			Color3.fromRGB(53, 68, 85),
			Enum.Material.Slate,
			true
		)
		piece(
			model,
			"Leg",
			Vector3.new(0.85, 1.8, 1) * scale,
			CFrame.new(side * 0.75 * scale, -2.4 * scale, 0),
			Color3.fromRGB(84, 94, 110),
			Enum.Material.Metal,
			true
		)
	end
	piece(
		model,
		"Crest",
		Vector3.new(0.5, 1.6, 0.5) * scale,
		CFrame.new(0, 2.4 * scale, 0) * CFrame.Angles(0, 0, math.pi / 4),
		color,
		Enum.Material.Neon,
		true
	)
	if def.Boss then
		for _, side in { -1, 1 } do
			piece(
				model,
				"CrownHorn",
				Vector3.new(0.45, 2, 0.7) * scale,
				CFrame.new(side * 1.1 * scale, 2.5 * scale, 0) * CFrame.Angles(0, 0, side * -0.3),
				color,
				Enum.Material.Neon,
				true
			)
		end
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "EnemyHealth"
	gui.Size = UDim2.fromOffset(if def.Boss then 210 else 140, 42)
	gui.StudsOffset = Vector3.new(0, scale * 4, 0)
	gui.MaxDistance = 85
	gui.Parent = root
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(15, 23, 38)
	label.BackgroundTransparency = 0.2
	label.TextColor3 = Color3.fromRGB(233, 244, 255)
	label.Font = Enum.Font.GothamMedium
	label.TextSize = 13
	label.TextWrapped = true
	label.Text = def.Name
	label.Parent = gui
	return model, center, label
end
return Appearance
