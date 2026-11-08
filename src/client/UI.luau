--!strict
local UI = {}
UI.Colors = {
	Ink = Color3.fromRGB(12, 19, 34),
	Card = Color3.fromRGB(23, 34, 52),
	Text = Color3.fromRGB(237, 244, 248),
	Muted = Color3.fromRGB(159, 180, 197),
	Gold = Color3.fromRGB(255, 194, 111),
	Teal = Color3.fromRGB(79, 216, 207),
}
function UI.frame(parent, name, size, position, color)
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = position
	f.BackgroundColor3 = color or UI.Colors.Card
	f.BackgroundTransparency = 0.08
	f.BorderSizePixel = 0
	f.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(69, 92, 113)
	stroke.Transparency = 0.5
	stroke.Thickness = 1
	stroke.Parent = f
	return f
end
function UI.text(parent, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or UI.Colors.Text
	label.Font = Enum.Font.GothamMedium
	label.TextSize = textSize or 16
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end
function UI.button(parent, text, size, position, callback, accent)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = position
	b.Text = text
	b.BackgroundColor3 = if accent then Color3.fromRGB(90, 66, 37) else Color3.fromRGB(34, 65, 80)
	b.TextColor3 = if accent then UI.Colors.Gold else UI.Colors.Text
	b.BorderSizePixel = 0
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 15
	b.TextWrapped = true
	b.AutoButtonColor = true
	b.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = b
	b.Activated:Connect(callback)
	return b
end
function UI.bar(parent, name, color, size, position)
	local bg = UI.frame(parent, name, size, position, UI.Colors.Ink)
	bg.ClipsDescendants = true
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Parent = bg
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = fill
	return fill, bg
end
function UI.panel(parent, title)
	local overlay = Instance.new("Frame")
	overlay.Name = title
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.new()
	overlay.BackgroundTransparency = 0.36
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 20
	overlay.Parent = parent
	local panel =
		UI.frame(overlay, "Panel", UDim2.fromScale(0.93, 0.88), UDim2.fromScale(0.5, 0.5), UI.Colors.Ink)
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.ZIndex = 21
	local cap = Instance.new("UISizeConstraint")
	cap.MaxSize = Vector2.new(760, 740)
	cap.Parent = panel
	UI.text(panel, title, UDim2.new(1, -112, 0, 52), UDim2.fromOffset(18, 4), 22, UI.Colors.Gold).ZIndex = 22
	local close = UI.button(panel, "Close", UDim2.fromOffset(76, 42), UDim2.new(1, -90, 0, 10), function()
		overlay.Visible = false
	end)
	close.ZIndex = 23
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -28, 1, -78)
	scroll.Position = UDim2.fromOffset(14, 66)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.ScrollBarThickness = 4
	scroll.ZIndex = 22
	scroll.Parent = panel
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
	return overlay, scroll
end
function UI.card(parent, title, description, buttonText, callback)
	local card = UI.frame(parent, title, UDim2.new(1, -8, 0, 106), UDim2.new())
	card.ZIndex = 23
	local heading = UI.text(card, title, UDim2.new(0.64, -14, 0, 32), UDim2.fromOffset(12, 6), 17)
	heading.ZIndex = 24
	local body =
		UI.text(card, description, UDim2.new(0.64, -14, 0, 60), UDim2.fromOffset(12, 38), 14, UI.Colors.Muted)
	body.ZIndex = 24
	local button =
		UI.button(card, buttonText, UDim2.new(0.34, -8, 0, 56), UDim2.new(0.66, 0, 0.5, -28), callback, true)
	button.ZIndex = 25
	return card, heading, body, button
end
return UI
