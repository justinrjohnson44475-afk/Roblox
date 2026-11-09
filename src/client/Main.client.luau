--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
if Shared:GetAttribute("AscensionEnabled") then
	return
end
local Config = require(Shared.Config)
local Progression = require(Shared.Progression)
local UI = require(script.Parent.UI)
local Effects = require(script.Parent.Effects)
local remotes = ReplicatedStorage:WaitForChild("RiftRemotes")
local action, stateEvent = remotes:WaitForChild("Action"), remotes:WaitForChild("State")
local gui = Instance.new("ScreenGui")
gui.Name = "RiftwakeHUD"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")
local C = UI.Colors
local heading = UI.text(gui, "RIFTWAKE", UDim2.fromOffset(225, 32), UDim2.fromOffset(18, 8), 28, C.Gold)
heading.Font = Enum.Font.GothamBold
local location =
	UI.text(gui, "ASCEND BEYOND THE STORM", UDim2.fromOffset(240, 20), UDim2.fromOffset(20, 39), 11, C.Muted)
local objectiveCard = UI.frame(gui, "JourneyGoal", UDim2.fromOffset(280, 100), UDim2.fromOffset(18, 74))
UI.text(objectiveCard, "NEXT ASCENSION", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 8), 11, C.Teal)
local objective =
	UI.text(objectiveCard, "Enter Verdant Reach", UDim2.new(1, -24, 0, 62), UDim2.fromOffset(12, 30), 16)
local currency =
	UI.text(gui, "Loading profile…", UDim2.fromOffset(285, 25), UDim2.fromOffset(20, 184), 15, C.Gold)
local resources = UI.frame(gui, "CharacterState", UDim2.new(0.44, 0, 0, 92), UDim2.new(0.5, 0, 1, -100))
resources.AnchorPoint = Vector2.new(0.5, 0)
local cap = Instance.new("UISizeConstraint")
cap.MaxSize = Vector2.new(460, 92)
cap.MinSize = Vector2.new(240, 92)
cap.Parent = resources
local health, healthBG =
	UI.bar(resources, "Health", C.Teal, UDim2.new(0.57, -18, 0, 12), UDim2.fromOffset(12, 30))
local focus, focusBG =
	UI.bar(resources, "Focus", C.Gold, UDim2.new(0.43, -18, 0, 12), UDim2.new(0.57, 6, 0, 30))
local healthText = UI.text(resources, "HEALTH", UDim2.new(0.57, -18, 0, 20), UDim2.fromOffset(12, 7), 12)
local focusText = UI.text(resources, "FOCUS", UDim2.new(0.43, -12, 0, 20), UDim2.new(0.57, 6, 0, 7), 12)
local xp =
	UI.bar(resources, "XP", Color3.fromRGB(145, 150, 235), UDim2.new(1, -24, 0, 5), UDim2.fromOffset(12, 76))
local level =
	UI.text(resources, "LV.1 · FRACTURED", UDim2.new(1, -24, 0, 23), UDim2.fromOffset(12, 47), 12, C.Muted)
local toast = UI.text(gui, "", UDim2.new(0.9, 0, 0, 48), UDim2.new(0.5, 0, 0.69, 0), 16, C.Gold)
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.TextXAlignment = Enum.TextXAlignment.Center
local saveText = UI.text(gui, "", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 0), 11, C.Muted)
saveText.AnchorPoint = Vector2.new(0, 1)
saveText.Position = UDim2.new(0, 12, 1, -4)
local bossFrame = UI.frame(gui, "Boss", UDim2.new(0.4, 0, 0, 62), UDim2.new(0.5, 0, 0, 10))
bossFrame.AnchorPoint = Vector2.new(0.5, 0)
bossFrame.Visible = false
local bossName = UI.text(bossFrame, "WARDEN", UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 2), 16, C.Gold)
local bossHealth = UI.bar(
	bossFrame,
	"BossHealth",
	Color3.fromRGB(237, 137, 88),
	UDim2.new(1, -24, 0, 8),
	UDim2.fromOffset(12, 39)
)
local forge, forgeScroll = UI.panel(gui, "RELIC FORGE")
local journal, journalScroll = UI.panel(gui, "JOURNEY & SETTINGS")
local reading, readingScroll = UI.panel(gui, "OPTIONAL CHRISTIAN READING")
local panels = { forge, journal, reading }
local function show(panel)
	for _, other in panels do
		other.Visible = other == panel
	end
	local button = panel:FindFirstChildWhichIsA("TextButton", true)
	if UserInputService.GamepadEnabled and button then
		GuiService.SelectedObject = button
	end
end
local journeyButton = UI.button(
	gui,
	"Journey",
	UDim2.fromOffset(98, 44),
	UDim2.new(1, -116, 0, 10),
	function()
		show(journal)
	end
)
local state = nil
local upgradeCards, pathCards, colorCards, regionCards = {}, {}, {}, {}
local function forgeAction(name, item)
	action:FireServer(name, item)
end
local intro = UI.text(
	forgeScroll,
	"Permanent upgrades. Known prices. Free build changes.\nUse the forge in Dawn Sanctuary to shape your rig.",
	UDim2.new(1, -12, 0, 52),
	UDim2.new(),
	15,
	C.Muted
)
intro.ZIndex = 23
for _, id in { "power", "guard", "flow" } do
	local def = Config.Upgrades[id]
	local card, title, body, button = UI.card(forgeScroll, def.Name, def.Effect, "Upgrade", function()
		forgeAction("upgrade", id)
	end)
	upgradeCards[id] = { Title = title, Body = body, Button = button }
end
local _, formTitle, formBody, formButton = UI.card(forgeScroll, "Rig evolution", "", "Evolve", function()
	forgeAction("evolve")
end)
for _, id in { "vanguard", "strider", "arcanist" } do
	local def = Config.Paths[id]
	local _, title, body, button = UI.card(forgeScroll, def.Name, def.Description, "Equip · free", function()
		forgeAction("path", id)
	end)
	pathCards[id] = button
end
for _, id in { "amber", "sea", "violet" } do
	local def = Config.Cosmetics[id]
	local _, _, _, button = UI.card(
		forgeScroll,
		def.Name .. " energy",
		"Cosmetic only. Changes rig glow; no stat advantage.",
		"",
		function()
			forgeAction("color", id)
		end
	)
	colorCards[id] = button
end
if Config.SupporterPassId > 0 then
	UI.card(
		forgeScroll,
		"Ocean rig trim",
		"Optional permanent cosmetic pass. Roblox displays the current regional Robux price.",
		"View offer",
		function()
			forgeAction("supporter")
		end
	)
end
for _, region in Config.Regions do
	if region.Id ~= "hub" then
		local _, title, body, button = UI.card(journalScroll, region.Name, "", "", function() end)
		button.Active = false
		button.AutoButtonColor = false
		regionCards[region.Id] = { Body = body, Button = button }
	end
end
local guide = UI.text(
	journalScroll,
	"FIGHT → BREAK → FORGE → ASCEND\n\nStrike builds Focus. Watch orange ground warnings: dash clear or use Coreburst during the charge to interrupt it. An exposed core takes extra damage. At level 2 you earn Coreburst; level 5 unlocks Overdrive.\n\nBoss first clears award bonus XP/shards and unlock the next region. Return to the forge to buy stat upgrades, evolve your visible rig and change builds for free at level 3. Death ends an attempt; earned equipment and progress stay yours.\n\nInteract: F / controller L1 / native touch prompt.\n\nKeyboard: Mouse1 Strike · Q Dash · E Coreburst · R Overdrive. Gamepad: R2 Strike · B Dash · X Coreburst · Y Overdrive. Touch: use the four combat buttons; native controls handle movement/jump. Aim by facing the camera toward the enemy.\n\nThe Garden of Hope is explicitly Christian reading. It is voluntary, free, unrewarded and never required. No beliefs, declarations or reading behavior are recorded.\n\nStudio previews do not save by default. Sound/effects settings are local for this session. Robux purchases are disabled until configured and verified.",
	UDim2.new(1, -14, 0, 0),
	UDim2.new(),
	16
)
guide.AutomaticSize = Enum.AutomaticSize.Y
guide.ZIndex = 23
local soundButton
soundButton = UI.button(journalScroll, "Sound: on", UDim2.new(1, -10, 0, 48), UDim2.new(), function()
	Effects.Muted = not Effects.Muted
	soundButton.Text = if Effects.Muted then "Sound: muted" else "Sound: on"
end)
soundButton.ZIndex = 23
local effectButton
effectButton = UI.button(journalScroll, "Effects: gentle", UDim2.new(1, -10, 0, 48), UDim2.new(), function()
	Effects.Reduced = not Effects.Reduced
	effectButton.Text = if Effects.Reduced then "Effects: reduced" else "Effects: gentle"
end)
effectButton.ZIndex = 23
local gospel = UI.text(
	readingScroll,
	"GARDEN OF HOPE\nChristian teaching about Jesus Christ\n\nThis reading is optional. Close it whenever you wish. It gives no currency, progress or advantage. People of every faith and no faith are welcome.\n\nChristians believe God loves the world and gave His Son, Jesus Christ (John 3:16). The gospel teaches that Christ died for our sins, was buried, and rose again (1 Corinthians 15:3–4). Salvation is God’s gift, received through faith, not earned by works (Ephesians 2:8–9).\n\nBeating enemies or helping in this game does not earn salvation. Christian love calls people to love God and their neighbors (Matthew 22:37–39), show compassion (Luke 10:25–37), and speak with gentleness and respect (1 Peter 3:15).\n\nThese are original summaries, not Bible-translation quotations. No response or personal information is requested or recorded. The rest of Riftwake is fully available without reading.",
	UDim2.new(1, -14, 0, 0),
	UDim2.new(),
	17
)
gospel.AutomaticSize = Enum.AutomaticSize.Y
gospel.ZIndex = 23
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer and triggeringPlayer ~= player then
		return
	end
	if prompt.Name == "ChristianReading" then
		show(reading)
	end
end)
local actions = {
	{
		Id = "strike",
		Label = "STRIKE",
		Key = "M1",
		Binding = Enum.UserInputType.MouseButton1,
		Pad = Enum.KeyCode.ButtonR2,
		Unlock = 1,
	},
	{
		Id = "dash",
		Label = "DASH",
		Key = "Q",
		Binding = Enum.KeyCode.Q,
		Pad = Enum.KeyCode.ButtonB,
		Unlock = 1,
	},
	{
		Id = "burst",
		Label = "COREBURST",
		Key = "E",
		Binding = Enum.KeyCode.E,
		Pad = Enum.KeyCode.ButtonX,
		Unlock = 2,
	},
	{
		Id = "overdrive",
		Label = "OVERDRIVE",
		Key = "R",
		Binding = Enum.KeyCode.R,
		Pad = Enum.KeyCode.ButtonY,
		Unlock = 5,
	},
}
local abilityButtons = {}
local function input(id)
	for _, panel in panels do
		if panel.Visible then
			return
		end
	end
	if UserInputService:GetFocusedTextBox() then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local direction = camera.CFrame.LookVector
	-- Third-person camera direction is the aim reference; damage/target selection stays on the server.
	action:FireServer(id, { x = direction.X, y = direction.Y, z = direction.Z })
	if id == "strike" then
		local c = player.Character
		local rig = c and c:FindFirstChild("RelicRig")
		local joint = rig and rig:FindFirstChild("StrikeJoint", true)
		if joint then
			local neutral = CFrame.new(0, -0.2, -0.2)
			joint.C0 = neutral * CFrame.Angles(-0.9, 0.3, 0.25)
			TweenService:Create(joint, TweenInfo.new(0.26), { C0 = neutral }):Play()
		end
	end
end
for i, def in actions do
	local button = UI.button(
		gui,
		def.Key .. "\n" .. def.Label,
		UDim2.fromOffset(86, 58),
		UDim2.new(0.5, (i - 2.5) * 94, 1, -172),
		function()
			input(def.Id)
		end,
		def.Id == "burst"
	)
	button.AnchorPoint = Vector2.new(0.5, 0)
	abilityButtons[def.Id] = button
	local function bound(_, inputState)
		if inputState == Enum.UserInputState.Begin then
			input(def.Id)
		end
		return Enum.ContextActionResult.Pass
	end
	if def.Id == "strike" then
		ContextActionService:BindAction("Rift_" .. def.Id, bound, false, def.Pad)
	else
		ContextActionService:BindAction("Rift_" .. def.Id, bound, false, def.Binding, def.Pad)
	end
end
UserInputService.InputBegan:Connect(function(key, processed)
	if not processed and key.UserInputType == Enum.UserInputType.MouseButton1 then
		input("strike")
	end
end)
local compact = false
local narrow = false
local short = false
local function layout()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	compact = camera.ViewportSize.X < 760 and camera.ViewportSize.Y > camera.ViewportSize.X * 0.9
	narrow = camera.ViewportSize.X < 1000
	short = camera.ViewportSize.Y < 500
	heading.TextSize = if compact then 23 else 28
	heading.Size = UDim2.fromOffset(if compact then 190 else 225, 32)
	objectiveCard.Size = UDim2.fromOffset(if compact then 220 else 280, if compact then 88 else 100)
	objective.Size = UDim2.new(1, -24, 0, if compact then 54 else 62)
	objective.TextSize = if compact then 14 else 16
	currency.Position = UDim2.fromOffset(20, if short then 53 elseif compact then 165 else 184)
	resources.Size = if compact then UDim2.new(0.8, 0, 0, 92) else UDim2.new(0.44, 0, 0, 92)
	resources.Position = UDim2.new(0.5, 0, 1, if compact then -280 else -100)
	bossFrame.Size = if compact then UDim2.new(0.9, 0, 0, 62) else UDim2.new(0.4, 0, 0, 62)
	bossFrame.Position = UDim2.new(0.5, 0, 0, if narrow then 74 else 10)
	for i, def in actions do
		local b = abilityButtons[def.Id]
		b.Size = UDim2.fromOffset(if compact then 72 else 86, if compact then 62 else 58)
		b.Position = if compact
			then UDim2.new(1, -130 + (i - 1) % 2 * 79, 1, -174 + math.floor((i - 1) / 2) * 70)
			else UDim2.new(0.5, (i - 2.5) * 94, 1, -172)
		b.TextSize = if compact then 12 else 14
	end
end
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(layout)
end
layout()
local toastUntil = 0
stateEvent.OnClientEvent:Connect(function(nextState)
	if nextState.OpenForge then
		show(forge)
		return
	end
	state = nextState
	local form = Config.Forms[state.Form + 1]
	for _, region in Config.Regions do
		if region.Id == state.Region then
			location.Text = string.upper(region.Name)
		end
	end
	objective.Text = state.Goal
	currency.Text = string.format("%d SHARDS    ◇ %d CORES", state.Shards, state.Cores)
	health.Size = UDim2.fromScale(math.clamp(state.Health / state.MaxHealth, 0, 1), 1)
	focus.Size = UDim2.fromScale(state.Focus / 100, 1)
	xp.Size = UDim2.fromScale(
		math.clamp((state.XP - state.LevelXP) / math.max(1, state.NextXP - state.LevelXP), 0, 1),
		1
	)
	healthText.Text = string.format("HP %d / %d", state.Health, state.MaxHealth)
	focusText.Text = string.format("FOCUS %d", state.Focus)
	level.Text =
		string.format("LV.%d · %s · %s", state.Level, string.upper(form.Name), string.upper(state.Path))
	saveText.Text = if state.SaveWarning
		then "SAVE CONNECTION PROBLEM — recent progress is not confirmed saved"
		elseif state.SaveMode:find("Studio") then state.SaveMode
		else ""
	saveText.TextColor3 = if state.SaveWarning then Color3.fromRGB(255, 151, 122) else C.Muted
	if state.Notice then
		toast.Text = state.Notice
		toastUntil = os.clock() + 3.4
	end
	for _, def in actions do
		local cd = state.Cooldowns[def.Id]
		abilityButtons[def.Id].Text = if state.Level < def.Unlock
			then "LV." .. def.Unlock .. "\n" .. def.Label
			elseif cd > 0 then string.format("%.1fs\n%s", cd, def.Label)
			else (if compact and UserInputService.TouchEnabled then "" else def.Key .. "\n") .. def.Label
	end
	for id, card in upgradeCards do
		local def = Config.Upgrades[id]
		local rank = state.Upgrades[id]
		card.Title.Text = def.Name .. " · " .. rank .. "/" .. def.Max
		card.Body.Text = def.Effect
		card.Button.Text = if rank >= def.Max then "MAXED" else (def.BaseCost + rank * def.Step) .. " shards"
	end
	local nextForm = Config.Forms[state.Form + 2]
	formTitle.Text = form.Name .. " → " .. (if nextForm then nextForm.Name else "Complete")
	formBody.Text = if nextForm
		then "Lv." .. nextForm.Level .. " + required warden clear. Larger gauntlet, armor and rig silhouette."
		else "Your rig has reached its final slice form."
	formButton.Text = if nextForm
		then nextForm.Shards .. " shards\n" .. nextForm.Cores .. " cores"
		else "STORMFORGED"
	for id, button in pathCards do
		button.Text = if state.Path == id
			then "EQUIPPED"
			elseif state.Level < 3 then "Lv.3 unlock"
			else "Equip · free"
	end
	for id, button in colorCards do
		button.Text = if state.Equipped == id
			then "EQUIPPED"
			elseif state.Owned[id] then "Equip"
			else Config.Cosmetics[id].Cost .. " shards"
	end
	for _, region in Config.Regions do
		local card = regionCards[region.Id]
		if card then
			local unlocked = state.Level >= region.Level and (not region.Clear or state.Clears[region.Clear])
			card.Body.Text = "Gate in Dawn Sanctuary · Lv."
				.. region.Level
				.. (if region.Clear then " + previous warden clear" else " · Your first expedition")
			card.Button.Text = if state.Clears[region.Boss]
				then "WARDEN CLEARED"
				elseif unlocked then "GATE OPEN"
				else "LOCKED"
		end
	end
end)
remotes:WaitForChild("Effects").OnClientEvent:Connect(Effects.play)
local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.15 then
		return
	end
	elapsed = 0
	if os.clock() > toastUntil then
		toast.Text = ""
	end
	if not state then
		return
	end
	local c = player.Character
	local root = c and c:FindFirstChild("HumanoidRootPart")
	local closest, distance = nil, 95
	local folder = workspace:FindFirstChild("RiftEnemies")
	if root and folder then
		for _, model in folder:GetChildren() do
			local kind = model:GetAttribute("Kind")
			if
				kind
				and Config.Enemies[kind].Boss
				and model.PrimaryPart
				and model:GetAttribute("State") ~= "dead"
				and model:GetAttribute("Region") == state.Region
			then
				local d = (model.PrimaryPart.Position - root.Position).Magnitude
				if d < distance then
					closest = model
					distance = d
				end
			end
		end
	end
	bossFrame.Visible = closest ~= nil
	objectiveCard.Visible = not short and not (narrow and closest ~= nil)
	currency.Visible = not (narrow and closest ~= nil)
	if closest then
		local def = Config.Enemies[closest:GetAttribute("Kind")]
		local status = closest:GetAttribute("State")
		bossName.Text = def.Name
			.. " · PHASE "
			.. tostring(closest:GetAttribute("Phase") or 1)
			.. (if status == "windup" then " · BREAK!" elseif status == "exposed" then " · EXPOSED" else "")
		bossHealth.Size = UDim2.fromScale(
			math.clamp(
				(closest:GetAttribute("Health") or def.Health)
					/ (closest:GetAttribute("MaxHealth") or def.Health),
				0,
				1
			),
			1
		)
	end
end)
action:FireServer("state")
