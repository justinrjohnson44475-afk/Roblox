--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared").Config)
local UI = require(script.Parent.UI)
local remotes = ReplicatedStorage:WaitForChild("HarborRemotes")
local action = remotes:WaitForChild("Action")
local stateEvent = remotes:WaitForChild("State")
local gui = Instance.new("ScreenGui")
gui.Name = "HarborlightHUD"
gui.ResetOnSpawn = false

gui.Parent = player:WaitForChild("PlayerGui")
local hud = UI.frame(gui, "Status", UDim2.new(1, -24, 0, 146), UDim2.fromOffset(12, 10))
local title =
	UI.text(hud, "HARBORLIGHT · RESTORE TOGETHER", UDim2.new(1, -16, 0, 24), UDim2.fromOffset(8, 4), 17)
local stats = UI.text(hud, "Loading your profile…", UDim2.new(1, -16, 0, 26), UDim2.fromOffset(8, 31), 16)
local objective = UI.text(
	hud,
	"Recover supplies from teal crates, then contribute at the glowing repair",
	UDim2.new(1, -16, 0, 42),
	UDim2.fromOffset(8, 57),
	16
)
objective.TextScaled = true
local objectiveSize = Instance.new("UITextSizeConstraint")
objectiveSize.MinTextSize = 12
objectiveSize.MaxTextSize = 16
objectiveSize.Parent = objective
stats.TextScaled = true
local statsSize = Instance.new("UITextSizeConstraint")
statsSize.MinTextSize = 12
statsSize.MaxTextSize = 16
statsSize.Parent = stats
local notice = UI.text(hud, "", UDim2.new(1, -16, 0, 35), UDim2.fromOffset(8, 101), 13)
local help, helpScroll = UI.panel(gui, "Crew guide & settings")
local shop, shopScroll = UI.panel(gui, "Lantern workshop")
local reading, readingScroll = UI.panel(gui, "Optional Christian reading")
local function show(panel)
	help.Visible = false
	shop.Visible = false
	reading.Visible = false
	panel.Visible = true
end
UI.button(gui, "Guide / settings", UDim2.fromOffset(148, 44), UDim2.new(0, 12, 0, 164), function()
	show(help)
end)
UI.button(gui, "Lantern colors", UDim2.fromOffset(148, 44), UDim2.new(1, -160, 0, 164), function()
	show(shop)
end)
local helpText = UI.text(
	helpScroll,
	"Restore the harbor together.\n\n1. Walk to a teal supply crate. Use the displayed key, touch button or controller prompt to recover one supply.\n2. Carry up to five supplies.\n3. Follow the current repair named on your HUD and contribute. Each supply earns two tokens.\n4. Finish the pier, greenhouse and beacon. A fresh shift starts after completion or the timer ends. Personal tokens remain.\n\nAll lantern colors are cosmetic. No purchase changes rewards. Resetting your character drops carried supplies.\n\nThe Garden of Hope offers clearly labeled, optional Christian reading. There are no rewards for reading, and it is never required.\n\nStudio preview uses temporary profiles unless a test DataStore is explicitly enabled. Live save warnings mean recent progress may be at risk. Settings below last for this session.",
	UDim2.new(1, -12, 0, 0),
	UDim2.fromOffset(0, 0),
	16
)
helpText.AutomaticSize = Enum.AutomaticSize.Y
helpText.TextXAlignment = Enum.TextXAlignment.Left
helpText.ZIndex = 7
local settingsRow = Instance.new("Frame")
settingsRow.BackgroundTransparency = 1
settingsRow.Size = UDim2.new(1, 0, 0, 106)
settingsRow.Parent = helpScroll
settingsRow.ZIndex = 7
local function positionSettings()
	settingsRow.Position = UDim2.fromOffset(0, helpText.AbsoluteSize.Y + 16)
end
helpText:GetPropertyChangedSignal("AbsoluteSize"):Connect(positionSettings)
local muted = false
local reduced = false
local sound = Instance.new("Sound")
sound.Name = "LocalContributionFeedback"
sound.SoundId = "rbxasset://sounds/electronicpingshort.wav"
sound.Volume = 0.25
sound.Parent = SoundService
local muteButton
muteButton = UI.button(settingsRow, "Sound: on", UDim2.new(1, -12, 0, 44), UDim2.fromOffset(0, 0), function()
	muted = not muted
	muteButton.Text = if muted then "Sound: muted" else "Sound: on"
end)
muteButton.ZIndex = 8
local reduceButton
reduceButton = UI.button(
	settingsRow,
	"Effects: gentle",
	UDim2.new(1, -12, 0, 44),
	UDim2.fromOffset(0, 54),
	function()
		reduced = not reduced
		reduceButton.Text = if reduced then "Effects: reduced" else "Effects: gentle"
	end
)
reduceButton.ZIndex = 8
local shopInfo = UI.text(
	shopScroll,
	"Earn tokens by contributing supplies. Colors change your lantern only.",
	UDim2.new(1, -12, 0, 54),
	UDim2.fromOffset(0, 0),
	16
)
shopInfo.ZIndex = 7
local buttons = {}
for i, id in { "amber", "sea", "violet" } do
	local cosmetic = Config.Cosmetics[id]
	buttons[id] = UI.button(
		shopScroll,
		cosmetic.Name,
		UDim2.new(1, -12, 0, 54),
		UDim2.fromOffset(0, 60 + (i - 1) * 64),
		function()
			action:FireServer("equip", id)
		end
	)
	buttons[id].ZIndex = 7
end
local offer = if Config.SupporterPassId > 0
	then "Optional Robux pass: permanent ocean lantern trim. Cosmetic only. Roblox shows the current price."
	else "Robux purchases are not enabled in this build."
UI.text(shopScroll, offer, UDim2.new(1, -12, 0, 76), UDim2.fromOffset(0, 255), 16).ZIndex = 7
if Config.SupporterPassId > 0 then
	UI.button(shopScroll, "View Roblox offer", UDim2.new(1, -12, 0, 54), UDim2.fromOffset(0, 340), function()
		action:FireServer("supporter")
	end).ZIndex =
		7
end
local gospel = UI.text(
	readingScroll,
	"GARDEN OF HOPE\nChristian teaching about Jesus Christ\n\nThis reading is optional. You can close it at any time. Reading gives no currency, progress or advantage. People of every faith and no faith are welcome in Harborlight.\n\nChristians believe God loves the world and gave His Son, Jesus Christ (John 3:16). The gospel teaches that Christ died for our sins, was buried, and rose again (1 Corinthians 15:3–4). Salvation is God’s gift, received through faith, not earned by good works (Ephesians 2:8–9).\n\nHelping in this game does not earn salvation. Christian love calls people to love God and their neighbors (Matthew 22:37–39), to show compassion (Luke 10:25–37), and to speak with gentleness and respect (1 Peter 3:15).\n\nThese are original summaries, not quotations from a Bible translation. No response, personal information or declaration is requested or recorded. Thank you for visiting; the harbor is ready whenever you are.",
	UDim2.new(1, -12, 0, 0),
	UDim2.fromOffset(0, 0),
	17
)
gospel.AutomaticSize = Enum.AutomaticSize.Y
gospel.TextXAlignment = Enum.TextXAlignment.Left
gospel.ZIndex = 7
ProximityPromptService.PromptTriggered:Connect(function(prompt, triggeringPlayer)
	if triggeringPlayer and triggeringPlayer ~= player then
		return
	end
	if prompt.Name == "ChristianReading" and prompt:IsDescendantOf(workspace) then
		show(reading)
	end
end)
local previousTokens = nil
stateEvent.OnClientEvent:Connect(function(state)
	stats.Text = string.format(
		"Bag %d/%d · %d tokens · %d repairs",
		state.Carried,
		Config.Capacity,
		state.Tokens,
		state.Repairs
	)
	objective.Text = state.Project
		.. (if state.Complete then "" else string.format(" · %d/%d", state.Progress, state.Required))
		.. string.format("\n%ds · Recover → contribute → restore", state.Seconds)
	if state.SaveWarning then
		notice.Text = "Save connection problem — recent progress is not confirmed saved"
	elseif state.Notice then
		notice.Text = state.Notice
	elseif state.SaveMode:find("Studio") then
		notice.Text = state.SaveMode
	end
	for id, button in buttons do
		button.Text = Config.Cosmetics[id].Name
			.. (
				if state.Equipped == id
					then " · equipped"
					elseif state.Owned[id] then " · owned, select to equip"
					else " · " .. Config.Cosmetics[id].Cost .. " tokens"
			)
	end
	if previousTokens and state.Tokens > previousTokens then
		if not muted then
			sound:Play()
		end
		if not reduced then
			title.TextColor3 = Color3.fromRGB(255, 200, 110)
			TweenService:Create(title, TweenInfo.new(0.6), { TextColor3 = Color3.fromRGB(255, 243, 220) })
				:Play()
		end
	end
	previousTokens = state.Tokens
end)
action:FireServer("state")
-- The profile may still be loading when this script starts; server sends on load and once per second.
