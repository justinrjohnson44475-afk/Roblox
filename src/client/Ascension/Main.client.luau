--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
if not Shared:GetAttribute("AscensionEnabled") then
	return
end
local Input = game:GetService("ContextActionService")
local UIS = game:GetService("UserInputService")
local Run = game:GetService("RunService")
local player = Players.LocalPlayer
local remotes = RS:WaitForChild("AscensionRemotes")
local source = RS:WaitForChild("AscensionSource")
local animations = require(Shared.Ascension.AnimationPlayback).new(
	source.SourceClips,
	require(Shared.Ascension.AssetManifest)
)
local presentation = require(script.Parent.Presentation).new(UIS.TouchEnabled)
local audio = require(script.Parent.Audio).new(require(Shared.Ascension.AssetManifest), UIS.TouchEnabled)
local gui = Instance.new("ScreenGui")
gui.Name = "AscensionSignature"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.Parent = player:WaitForChild("PlayerGui")
local function text(name, value, size, pos)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = value
	label.Size = size
	label.Position = pos
	label.BackgroundColor3 = Color3.fromRGB(15, 26, 30)
	label.BackgroundTransparency = 0.12
	label.TextColor3 = Color3.fromRGB(222, 238, 224)
	label.TextSize = 16
	label.Font = Enum.Font.GothamMedium
	label.TextWrapped = true
	label.Parent = gui
	return label
end
local gate = text(
	"Readiness",
	"ASCENSION · Connecting signature test…",
	UDim2.new(1, -24, 0, 48),
	UDim2.fromOffset(12, 4)
)
if not Run:IsStudio() then
	gate.Text = "ASCENSION BLOCKED · signature checkpoint requires owned assets and Studio verification"
	return
end
local boss = text(
	"Encounter",
	"VERDANT WARDEN\nBreak marked charges with Heavy/Coreburst; evade the impact.",
	UDim2.new(0.5, 0, 0, 56),
	UDim2.new(0.25, 0, 0, 58)
)
local hud = text("Resources", "", UDim2.new(0.52, 0, 0, 54), UDim2.new(0.24, 0, 1, -68))
local message = text(
	"Feedback",
	"Diagnostic collision proxies · authored meshes await import",
	UDim2.new(0.62, 0, 0, 45),
	UDim2.new(0.19, 0, 1, -119)
)
local session, seq, state = nil, 0, nil
local combo = 0
local comboAt = -100
local heldAt = 0
local isHeld = false
local locomotion = nil
local predicted = {}
local function send(action, extra)
	if not session then
		return
	end
	seq += 1
	local c = player.Character
	local root = c and c.PrimaryPart
	local aim = root and root.CFrame.LookVector or Vector3.new(0, 0, -1)
	local packet = {
		version = 2,
		session = session,
		seq = seq,
		action = action,
		aim = {
			x = aim.X,
			y = aim.Y,
			z = aim.Z,
		},
	}
	for k, v in extra or {} do
		packet[k] = v
	end
	remotes.Request:FireServer(packet)
	return seq
end
local function predict(action)
	local c = player.Character
	if not c then
		return
	end
	local name = action
	if action == "light" then
		combo = if os.clock() - comboAt < 1.2 then combo % 3 + 1 else 1
		comboAt = os.clock()
		name = "Light" .. combo
	elseif action == "heavy" then
		name = "Heavy"
	elseif action == "burst" then
		name = "Coreburst"
	elseif action == "overdrive" then
		name = "Overdrive"
	elseif action == "dash" then
		name = "DashForward"
	end
	local sequence = send(action)
	local track = animations:play(c, name, 0.03)
	if sequence and track then
		predicted[sequence] = { Track = track, At = os.clock() }
	end
end
local function button(label, x, y, fn)
	local b = Instance.new("TextButton")
	b.Text = label
	b.TextColor3 = Color3.fromRGB(231, 241, 223)
	b.BackgroundColor3 = Color3.fromRGB(36, 60, 59)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Size = UDim2.fromOffset(142, 32)
	b.Position = UDim2.fromOffset(x, y)
	b.Parent = gui
	b.Activated:Connect(fn)
	return b
end
button("ENTER WARDEN", 12, 122, function()
	send("enter")
end)
button("CREATE PARTY", 12, 158, function()
	send("partyCreate")
end)
button("READY", 12, 194, function()
	send("ready", { enabled = true })
end)
button("ACCEPT INVITE", 12, 230, function()
	send("partyAccept")
end)
button("LEAVE PARTY", 12, 266, function()
	send("partyLeave")
end)
local list = text(
	"Party",
	"Solo · create party, then click a player below to invite",
	UDim2.fromOffset(190, 88),
	UDim2.fromOffset(12, 302)
)
local inviteButtons = {}
local function rebuildInvites()
	for _, b in inviteButtons do
		b:Destroy()
	end
	inviteButtons = {}
	local row = 0
	for _, p in Players:GetPlayers() do
		if p ~= player then
			table.insert(
				inviteButtons,
				button("Invite " .. p.DisplayName, 12, 394 + row * 36, function()
					send("partyInvite", { target = p.UserId })
				end)
			)
			row += 1
		end
	end
end
Players.PlayerAdded:Connect(rebuildInvites)
Players.PlayerRemoving:Connect(rebuildInvites)
rebuildInvites()
button("POWER UPGRADE", 166, 122, function()
	send("upgrade", { item = "power" })
end)
button("EVOLVE", 166, 158, function()
	send("evolve")
end)
button("REDUCED MOTION", 166, 194, function()
	presentation.Motion = 0
end)
-- Optional reading stays entirely local: no request, profile field, reward or analytics.
local reading = text(
	"OptionalReading",
	"GARDEN OF HOPE · Optional Christian reading\n\nChristians believe God loves the world and offers grace through Jesus Christ (John 3:16; Ephesians 2:8–9). Beating enemies or helping in this game does not earn salvation. Love God and your neighbors, show compassion, and speak with gentleness and respect (Matthew 22:37–39; Luke 10:25–37; 1 Peter 3:15).\n\nOriginal summaries. Free, unrewarded, untracked, and independent of game completion. Everyone is welcome. Click the reading button again to close.",
	UDim2.new(0.6, 0, 0.55, 0),
	UDim2.new(0.2, 0, 0.2, 0)
)
reading.Visible = false
button("OPTIONAL READING", 166, 230, function()
	reading.Visible = not reading.Visible
end)
local function action(name, inputState)
	local begin = inputState == Enum.UserInputState.Begin
	local finish = inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel
	if name == "AscensionStrike" then
		if begin then
			heldAt = os.clock()
			isHeld = true
		end
		if finish and isHeld then
			isHeld = false
			predict(if os.clock() - heldAt >= 0.25 then "heavy" else "light")
		end
	elseif name == "AscensionGuard" then
		if begin then
			send("guard", { enabled = true })
		elseif finish then
			send("guard", { enabled = false })
		end
	elseif name == "AscensionSprint" then
		if begin or finish then
			send("sprint", { enabled = begin })
		end
	elseif begin then
		predict(({
			AscensionDash = "dash",
			AscensionBurst = "burst",
			AscensionOverdrive = "overdrive",
			AscensionHeavy = "heavy",
		})[name])
	end
	return Enum.ContextActionResult.Sink
end
Input:BindAction("AscensionStrike", action, true, Enum.UserInputType.MouseButton1, Enum.KeyCode.ButtonR2)
Input:BindAction("AscensionHeavy", action, true, Enum.KeyCode.T, Enum.KeyCode.ButtonR1)
Input:BindAction("AscensionGuard", action, true, Enum.KeyCode.F, Enum.KeyCode.ButtonL2)
Input:BindAction("AscensionSprint", action, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
Input:BindAction("AscensionDash", action, true, Enum.KeyCode.Q, Enum.KeyCode.ButtonB)
Input:BindAction("AscensionBurst", action, true, Enum.KeyCode.E, Enum.KeyCode.ButtonX)
Input:BindAction("AscensionOverdrive", action, true, Enum.KeyCode.R, Enum.KeyCode.ButtonY)
for i, name in { "Strike", "Heavy", "Guard", "Dash", "Burst", "Overdrive", "Sprint" } do
	Input:SetTitle("Ascension" .. name, name)
	Input:SetPosition(
		"Ascension" .. name,
		UDim2.new(1, -62 - ((i - 1) % 3) * 65, 1, -155 - math.floor((i - 1) / 3) * 62)
	)
end
local function character(model)
	presentation:clear()
	audio:clear()
	locomotion = nil
	local hum = model:WaitForChild("Humanoid")
	local animator = hum:WaitForChild("Animator")
	workspace.CurrentCamera.CameraSubject = hum
	local blade = model:FindFirstChild("RelicBladeProxy")
	local trail
	if blade then
		trail = Instance.new("Trail")
		trail.Attachment0 = blade:FindFirstChild("BladeBase")
		trail.Attachment1 = blade:FindFirstChild("BladeTip")
		trail.Lifetime = 0.12
		trail.Enabled = false
		trail.Color = ColorSequence.new(Color3.fromRGB(148, 242, 214))
		trail.Parent = blade
	end
	animator.AnimationPlayed:Connect(function(track)
		if trail then
			track:GetMarkerReachedSignal("TrailOn"):Connect(function()
				trail.Enabled = true
			end)
			track:GetMarkerReachedSignal("TrailOff"):Connect(function()
				trail.Enabled = false
			end)
			track.Stopped:Once(function()
				trail.Enabled = false
			end)
		end
	end)
end
player.CharacterRemoving:Connect(function(model)
	animations:remove(model)
	for _, p in predicted do
		p.Track:Stop(0)
	end
	predicted = {}
	presentation:clear()
	audio:clear()
end)
player.CharacterAdded:Connect(character)
if player.Character then
	task.spawn(character, player.Character)
end
remotes.State.OnClientEvent:Connect(function(value)
	state = value
	audio:music(if value.encounter then "boss" else "exploration")
	if session ~= value.session then
		session = value.session
		seq = 0
	end
	gate.Text = "ASCENSION · STUDIO SOURCE PREVIEW · "
		.. value.missing
		.. " assets await import/validation · progress not saved by default"
	hud.Text = string.format(
		"STAMINA %d   ·   FOCUS %d\nLv.%d  ·  %d shards  ·  %d cores",
		value.stamina,
		value.focus,
		value.profile.Level,
		value.profile.Shards,
		value.profile.Cores
	)
	if value.encounter then
		local e = value.encounter
		boss.Text = string.format(
			"VERDANT WARDEN · PHASE %d · %d/%d\n%s · %d-player roster",
			e.phase,
			e.health,
			e.maxHealth,
			e.state,
			e.size
		)
	else
		boss.Text =
			"VERDANT WARDEN · Signature encounter\nEnter solo or ready your party. Guard/parry basic strikes; evade or break marked core charges."
	end
	list.Text = if value.party
		then "Party: "
			.. #value.party.members
			.. "/4 · Leader "
			.. value.party.leader
			.. "\nAll members must Ready before the leader enters"
		elseif value.invite then "Invitation from " .. value.invite .. " · Accept within 30 seconds"
		else "Solo · create a party, then invite a player below"
	if value.notice then
		message.Text = value.notice
	end
end)
remotes.Gate.OnClientEvent:Connect(function(event)
	if event.kind == "rejected" then
		local p = predicted[event.sequence]
		if p then
			p.Track:Stop(0.04)
			predicted[event.sequence] = nil
		end
		message.Text = "Action rejected · " .. tostring(event.reason or "unavailable")
	end
end)
remotes.Combat.OnClientEvent:Connect(function(event)
	if event.sequence and event.actor == player.UserId then
		local p = predicted[event.sequence]
		if p then
			p.Track:Stop(0.04)
			predicted[event.sequence] = nil
		end
	end
	if event.result == "telegraph" then
		message.Text = if event.pattern == "core"
			then "CORE CHARGE · EVADE or HEAVY / COREBURST to break"
			else "STRIKE · GUARD, PARRY or EVADE"
	end
	if event.result == "corebreak" then
		message.Text = "CORE EXPOSED · commit your blade attacks now"
	end
	presentation:event(event, workspace:GetServerTimeNow())
	if typeof(event.position) == "Vector3" then
		audio:play(event.result, event.position, workspace:GetServerTimeNow())
	end
end)
Run.RenderStepped:Connect(function(dt)
	local now = os.clock()
	presentation:step(workspace:GetServerTimeNow(), dt)
	audio:step(workspace:GetServerTimeNow())
	for id, p in predicted do
		if now - p.At > 0.8 then
			p.Track:Stop(0.08)
			predicted[id] = nil
		end
	end
	local c = player.Character
	local h = c and c:FindFirstChildOfClass("Humanoid")
	if not c or not h or h.Health <= 0 then
		return
	end
	local nextClip = if h.FloorMaterial == Enum.Material.Air
		then (if c.PrimaryPart.AssemblyLinearVelocity.Y > 0 then "Jump" else "Fall")
		elseif h.MoveDirection.Magnitude < 0.1 then (if state and state.encounter
			then "CombatIdle"
			else "Idle")
		elseif h.WalkSpeed > 20 then "Sprint"
		else "Run"
	if nextClip ~= locomotion then
		if locomotion and animations.Tracks[c] and animations.Tracks[c][locomotion] then
			animations.Tracks[c][locomotion]:Stop(0.12)
		end
		locomotion = nextClip
		animations:play(c, nextClip, 0.12)
	end
	local camera = workspace.CurrentCamera
	if camera and presentation.Shake > 0.001 then
		camera.CFrame *= CFrame.Angles(
			math.sin(now * 63) * presentation.Shake * 0.02,
			math.cos(now * 51) * presentation.Shake * 0.02,
			0
		)
	end
end)
-- First state may arrive before this LocalScript has connected.
task.spawn(function()
	while not session do
		remotes.Request:FireServer({ version = 2, action = "state" })
		task.wait(1)
	end
end)
