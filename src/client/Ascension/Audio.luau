--!strict
local SoundService = game:GetService("SoundService")
local Budget = require(game:GetService("ReplicatedStorage").Shared.Ascension.Budget)
local Audio = {}
function Audio.new(manifest, mobile)
	local self =
		{ Budget = Budget.new(if mobile then 16 else 32), Voices = {}, Free = {}, Music = nil, Mode = nil }
	local buses = {}
	for _, name in { "Music", "Effects", "Ambience" } do
		local bus = Instance.new("SoundGroup")
		bus.Name = "Ascension" .. name
		bus.Volume = if name == "Music" then 0.6 else 0.8
		bus.Parent = SoundService
		buses[name] = bus
	end
	function self:play(name, position, now)
		local asset = manifest.Assets["audio:" .. name]
		if not asset or asset.RobloxId <= 0 then
			return
		end
		local id = Budget.acquire(self.Budget, now + 3)
		if not id then
			return
		end
		local anchor = table.remove(self.Free) or Instance.new("Part")
		anchor.Name = "AudioVoice"
		anchor.Size = Vector3.one * 0.1
		anchor.Anchored = true
		anchor.Transparency = 1
		anchor.CanCollide = false
		anchor.CanQuery = false
		anchor.CanTouch = false
		anchor.Position = position
		anchor.Parent = workspace
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. asset.RobloxId
		sound.SoundGroup = buses.Effects
		sound.RollOffMinDistance = 6
		sound.RollOffMaxDistance = 80
		sound.Volume = 0.5
		sound.Parent = anchor
		sound:Play()
		self.Voices[id] = { Sound = sound, Anchor = anchor }
	end
	function self:music(mode)
		if self.Mode == mode then
			return
		end
		self.Mode = mode
		if self.Music then
			self.Music:Stop()
			self.Music:Destroy()
			self.Music = nil
		end
		local asset = manifest.Assets["audio:" .. mode]
		if not asset or asset.RobloxId <= 0 then
			return
		end
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://" .. asset.RobloxId
		sound.SoundGroup = buses.Music
		sound.Looped = true
		sound.Volume = 0.35
		sound.Parent = SoundService
		sound:Play()
		self.Music = sound
	end
	function self:settings(music, effects)
		buses.Music.Volume = math.clamp(music, 0, 1)
		buses.Effects.Volume = math.clamp(effects, 0, 1)
	end
	function self:step(now)
		for _, id in Budget.expire(self.Budget, now) do
			local voice = self.Voices[id]
			voice.Sound:Destroy()
			voice.Anchor.Parent = nil
			table.insert(self.Free, voice.Anchor)
			self.Voices[id] = nil
		end
	end
	function self:clear()
		for id, voice in self.Voices do
			voice.Sound:Destroy()
			voice.Anchor.Parent = nil
			table.insert(self.Free, voice.Anchor)
			Budget.release(self.Budget, id)
		end
		self.Voices = {}
		if self.Music then
			self.Music:Destroy()
			self.Music = nil
		end
		self.Mode = nil
	end
	function self:destroy()
		self:clear()
		for _, p in self.Free do
			p:Destroy()
		end
		for _, bus in buses do
			bus:Destroy()
		end
	end
	return self
end
return Audio
