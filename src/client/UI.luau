--!strict
local UI = {}
local cream = Color3.fromRGB(255, 243, 220)
local navy = Color3.fromRGB(19, 39, 49)
function UI.frame(parent, name, size, position)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = navy
	frame.BackgroundTransparency = 0.08
	frame.BorderSizePixel = 0
	frame.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	return frame
end
function UI.text(parent, text, size, position, textSize)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = cream
	label.Font = Enum.Font.GothamMedium
	label.TextSize = textSize or 16
	label.TextWrapped = true
	label.Text = text
	label.Parent = parent
	return label
end
function UI.button(parent, text, size, position, onClick)
	local button = Instance.new("TextButton")
	button.Size = size
	button.Position = position
	button.Text = text
	button.TextColor3 = cream
	button.BackgroundColor3 = Color3.fromRGB(43, 88, 95)
	button.Font = Enum.Font.GothamMedium
	button.TextSize = 16
	button.TextWrapped = true
	button.BorderSizePixel = 0
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	button.Activated:Connect(onClick)
	return button
end
function UI.panel(parent, title)
	local panel = UI.frame(parent, title, UDim2.new(0.92, 0, 0.76, 0), UDim2.fromScale(0.04, 0.12))
	local constraint = Instance.new("UISizeConstraint")
	constraint.MaxSize = Vector2.new(640, 620)
	constraint.Parent = panel
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.ZIndex = 5
	UI.text(panel, title, UDim2.new(1, -90, 0, 48), UDim2.fromOffset(10, 4), 20).ZIndex = 6
	UI.button(panel, "Close", UDim2.fromOffset(72, 44), UDim2.new(1, -80, 0, 6), function()
		panel.Visible = false
	end).ZIndex =
		6
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -24, 1, -68)
	scroll.Position = UDim2.fromOffset(12, 60)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.CanvasSize = UDim2.new()
	scroll.ScrollBarThickness = 6
	scroll.ZIndex = 6
	scroll.Parent = panel
	panel.Visible = false
	return panel, scroll
end
return UI
