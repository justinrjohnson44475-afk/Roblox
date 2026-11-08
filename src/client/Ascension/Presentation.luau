--!strict
local Shared = game:GetService("ReplicatedStorage").Shared
local Budget = require(Shared.Ascension.Budget)
local Presentation = {}
function Presentation.new(mobile)
	local self = {
		Budget = Budget.new(if mobile then 96 else 256),
		Active = {},
		Free = {},
		Motion = 0.2,
		Flash = 0,
		Shake = 0,
		Telegraphs = {},
	}
	local folder = Instance.new("Folder")
	folder.Name = "AscensionLocalDebris"
	folder.Parent = workspace
	self.Folder = folder
	local function acquire(position, seed, now, large)
		local id = Budget.acquire(self.Budget, now + 1.3)
		if not id then
			return
		end
		local p = table.remove(self.Free) or Instance.new("Part")
		p.Name = "PresentationOnly"
		p.Anchored = true
		p.CanCollide = false
		p.CanTouch = false
		p.CanQuery = false
		p.Size = Vector3.one * (if large then 1.1 else 0.4)
		p.Material = Enum.Material.Slate
		p.Color = Color3.fromRGB(104, 122, 104)
		p.Transparency = 0
		p.CFrame = CFrame.new(position)
		p.Parent = folder
		local random = Random.new(seed)
		self.Active[id] = {
			Part = p,
			At = now,
			Position = position,
			Velocity = Vector3.new(
				random:NextNumber(-12, 12),
				random:NextNumber(10, 20),
				random:NextNumber(-12, 12)
			),
			Spin = random:NextNumber(-5, 5),
		}
	end
	function self:event(event, now)
		local pos = event.position
		if typeof(pos) ~= "Vector3" then
			return
		end
		local camera = workspace.CurrentCamera
		if not camera or (camera.CFrame.Position - pos).Magnitude > 140 then
			return
		end
		if event.result == "telegraph" then
			local old = self.Telegraphs[event.encounter]
			if old then
				old.Part:Destroy()
			end
			local p = Instance.new("Part")
			p.Name = if event.pattern == "core" then "EVADE_OR_COREBREAK" else "GUARD_PARRY_OR_EVADE"
			p.Shape = Enum.PartType.Cylinder
			p.Size = Vector3.new(
				0.08,
				if event.pattern == "core" then 26 else 12,
				if event.pattern == "core" then 26 else 12
			)
			p.CFrame = CFrame.new(pos.X, 0.1, pos.Z) * CFrame.Angles(0, 0, math.pi / 2)
			p.Material = Enum.Material.Neon
			p.Color = if event.pattern == "core"
				then Color3.fromRGB(255, 175, 70)
				else Color3.fromRGB(120, 218, 241)
			p.Transparency = 0.65
			p.Anchored = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Parent = folder
			self.Telegraphs[event.encounter] = { Part = p, Ends = event.ends or now + 1.5 }
			return
		end
		local heavy = event.result == "heavy"
			or event.result == "exposed"
			or event.result == "corebreak"
			or event.result == "ground"
		local impact = heavy or event.result == "light" or event.result == "parry" or event.result == "block"
		if impact then
			local count = if heavy then (if mobile then 8 else 18) else 3
			if (camera.CFrame.Position - pos).Magnitude > 65 then
				count = math.ceil(count / 3)
			end
			for i = 1, count do
				acquire(pos, (event.seed or 1) * 31 + i, now, heavy)
			end
			self.Shake = math.min(0.14, self.Shake + (if heavy then 0.08 else 0.025)) * self.Motion
		end
		if event.result == "corebreak" or event.result == "victory" then
			local t = self.Telegraphs[event.encounter]
			if t then
				t.Part:Destroy()
				self.Telegraphs[event.encounter] = nil
			end
		end
	end
	function self:step(now, dt)
		for id, d in self.Active do
			local age = now - d.At
			d.Part.CFrame = CFrame.new(d.Position + d.Velocity * age + Vector3.new(0, -18 * age * age, 0))
				* CFrame.Angles(age * d.Spin, age * d.Spin, 0)
			d.Part.Transparency = math.clamp((age - 0.5) / 0.8, 0, 1)
			if age >= 1.3 then
				Budget.release(self.Budget, id)
				d.Part.Parent = nil
				table.insert(self.Free, d.Part)
				self.Active[id] = nil
			end
		end
		for key, t in self.Telegraphs do
			if now >= t.Ends then
				t.Part:Destroy()
				self.Telegraphs[key] = nil
			end
		end
		self.Shake *= math.exp(-dt * 16)
	end
	function self:clear()
		for id, d in self.Active do
			d.Part.Parent = nil
			table.insert(self.Free, d.Part)
			Budget.release(self.Budget, id)
		end
		self.Active = {}
		for _, t in self.Telegraphs do
			t.Part:Destroy()
		end
		self.Telegraphs = {}
		self.Shake = 0
	end
	function self:destroy()
		self:clear()
		for _, p in self.Free do
			p:Destroy()
		end
		folder:Destroy()
	end
	return self
end
return Presentation
