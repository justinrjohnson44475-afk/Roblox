--!strict
local RunService = game:GetService("RunService")
local Provider = game:GetService("KeyframeSequenceProvider")
local AnimationService = {}
function AnimationService.new(source, manifest)
	local self = { Ids = {}, Tracks = {} }
	function self:id(name)
		local asset = manifest.Assets["animation:" .. name]
		if asset and asset.RobloxId > 0 and asset.Status == "engine-validated" then
			return "rbxassetid://" .. asset.RobloxId
		end
		-- Studio-only diagnostic playback does not clear the production readiness gate.
		if RunService:IsStudio() and source:FindFirstChild(name) then
			if not self.Ids[name] then
				self.Ids[name] = Provider:RegisterKeyframeSequence(source[name])
			end
			return self.Ids[name]
		end
		return nil
	end
	function self:play(model, name, fade)
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
			cache[name] = track
		end
		cache[name]:Play(fade or 0.08)
		return cache[name]
	end
	function self:remove(model)
		for _, track in self.Tracks[model] or {} do
			track:Stop(0)
			track:Destroy()
		end
		self.Tracks[model] = nil
	end
	return self
end
return AnimationService
