--!strict
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local Effects = { Reduced = false, Muted = false }
local count = 0
local sound = Instance.new("Sound")
sound.Name = "LocalRiftFeedback"
sound.Volume = 0.18
sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
sound.Parent = SoundService
local function part(position, size, color, shape)
	if count >= 55 then
		return nil
	end
	count += 1
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Transparency = 0.2
	p.Shape = shape or Enum.PartType.Ball
	p.Parent = workspace
	Debris:AddItem(p, 0.65)
	task.delay(0.7, function()
		count -= 1
	end)
	return p
end
local function pulse(position, radius, color)
	local p = part(position, Vector3.one, color)
	if p then
		TweenService:Create(
			p,
			TweenInfo.new(0.45, Enum.EasingStyle.Quad),
			{ Size = Vector3.one * radius, Transparency = 1 }
		):Play()
	end
end
function Effects.play(kind, position, target, value)
	local camera = workspace.CurrentCamera
	if not camera or (camera.CFrame.Position - position).Magnitude > 160 then
		return
	end
	local teal = Color3.fromRGB(91, 233, 218)
	local gold = Color3.fromRGB(255, 198, 112)
	if kind == "hit" then
		if not Effects.Reduced then
			pulse(position, 3, gold)
		end
		local anchor = part(position + Vector3.new(0, 3, 0), Vector3.one * 0.01, gold)
		if anchor then
			anchor.Transparency = 1
			local gui = Instance.new("BillboardGui")
			gui.Size = UDim2.fromOffset(85, 42)
			gui.AlwaysOnTop = true
			gui.Parent = anchor
			local text = Instance.new("TextLabel")
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.Text = tostring(value)
			text.Font = Enum.Font.GothamBold
			text.TextSize = 25
			text.TextColor3 = gold
			text.TextStrokeTransparency = 0.6
			text.Parent = gui
			TweenService
				:Create(anchor, TweenInfo.new(0.55), { Position = anchor.Position + Vector3.new(0, 3, 0) })
				:Play()
		end
	elseif kind == "dash" then
		if Effects.Reduced then
			return
		end
		for i = 1, 5 do
			pulse(position:Lerp(target, i / 5), 2, teal)
		end
	elseif kind == "strike" then
		if Effects.Reduced then
			return
		end
		local p = part(position + target * 4, Vector3.new(0.3, 4, 7), teal, Enum.PartType.Block)
		if p then
			p.CFrame = CFrame.lookAt(p.Position, p.Position + target)
				* CFrame.Angles(0, 0, if value == 3 then -0.7 else 0.7)
			TweenService:Create(p, TweenInfo.new(0.2), { Transparency = 1, Size = Vector3.new(0.1, 6, 10) })
				:Play()
		end
	elseif kind == "burst" or kind == "overdrive" then
		if not Effects.Reduced then
			pulse(position, if kind == "overdrive" then 38 else 24, teal)
		end
	elseif kind == "break" or kind == "level" or kind == "firstclear" or kind == "forge" then
		if not Effects.Reduced then
			pulse(position, if kind == "break" then 15 else 8, gold)
		end
		if not Effects.Muted then
			sound:Play()
		end
	end
end
return Effects
