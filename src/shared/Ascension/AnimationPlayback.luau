--!strict
local RunService = game:GetService("RunService")
local Provider = game:GetService("KeyframeSequenceProvider")
local AnimationService = {}
function AnimationService.new(source, manifest)
	local self = { Ids = {}, Tracks = {}, Channels = {} }
	function self:id(name)
		local asset = manifest.Assets["animation:" .. name]
		if asset and asset.RobloxId > 0 and asset.Status == "engine-validated" then
			return "rbxassetid://" .. asset.RobloxId
		end
		if RunService:IsStudio() and source:FindFirstChild(name) then
			if not self.Ids[name] then
				local ok, id = pcall(function()
					return Provider:RegisterKeyframeSequence(source[name])
				end)
				if not ok then
					warn("Ascension source clip registration failed", name)
					return nil
				end
				self.Ids[name] = id
			end
			return self.Ids[name]
		end
		return nil
	end
	function self:channel(name)
		if name:find("Dash") or name:find("WallRun") or name == "DoubleJump" then
			return "Mobility"
		end
		local clip = source:FindFirstChild(name)
		if
			clip
			and (
				clip.Priority == Enum.AnimationPriority.Idle
				or clip.Priority == Enum.AnimationPriority.Movement
			)
		then
			return "Locomotion"
		end
		return "Action"
	end
	function self:stop(model, channel, fade)
		local channels = self.Channels[model]
		local old = channels and channels[channel]
		if old then
			old:Stop(fade or 0.10)
			channels[channel] = nil
		end
	end
	function self:play(model, name, fade, speed)
		local hum = model:FindFirstChildOfClass("Humanoid")
		local animator = hum and hum:FindFirstChildOfClass("Animator")
		if not animator then
			return nil
		end
		local id = self:id(name)
		if not id then
			return nil
		end
		local cache = self.Tracks[model]
		if not cache then
			cache = {}
			self.Tracks[model] = cache
			self.Channels[model] = {}
		end
		if not cache[name] then
			local animation = Instance.new("Animation")
			animation.Name = name
			animation.AnimationId = id
			local ok, track = pcall(function()
				return animator:LoadAnimation(animation)
			end)
			animation:Destroy()
			if not ok then
				warn("Ascension animation failed", name)
				return nil
			end
			track.Name = name
			cache[name] = track
		end
		local channel = self:channel(name)
		local channels = self.Channels[model]
		if channels[channel] and channels[channel] ~= cache[name] then
			channels[channel]:Stop(fade or 0.08)
		end
		local track = cache[name]
		if channel == "Mobility" then
			track.Priority = Enum.AnimationPriority.Action3
		end
		channels[channel] = track
		track:Play(fade or 0.08, 1, speed or 1)
		return track
	end
	function self:remove(model)
		for _, track in self.Tracks[model] or {} do
			track:Stop(0)
			track:Destroy()
		end
		self.Tracks[model] = nil
		self.Channels[model] = nil
	end
	return self
end
return AnimationService
