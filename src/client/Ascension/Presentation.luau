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
		Echoes = {},
		Fades = {},
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
	function self:phase(model, now)
		if not model then
			return
		end
		local parts = {}
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") and part.Transparency < 1 then
				parts[part] = part.LocalTransparencyModifier
				part.LocalTransparencyModifier = math.max(part.LocalTransparencyModifier, 0.55)
			end
		end
		local prior = self.Fades[model]
		if prior then
			parts = prior.Parts
		end
		self.Fades[model] = { Parts = parts, Ends = now + 0.20 }
		-- Static pose echoes, no terrain/collision changes and no screen flash.
		self.Echoes[model] = { Next = now, Left = if mobile or self.Motion == 0 then 1 else 3 }
	end
	function self:echo(model, now)
		local index = 0
		for _, source in model:GetDescendants() do
			if not source:IsA("BasePart") or source.Transparency >= 1 then
				continue
			end
			index += 1
			if index > 18 then
				break
			end
			local id = Budget.acquire(self.Budget, now + 0.22)
			if not id then
				break
			end
			local part = table.remove(self.Free) or Instance.new("Part")
			part.Name = "PhaseEcho"
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Size = source.Size
			part.CFrame = source.CFrame * CFrame.new(if index % 2 == 0 then 0.10 else -0.10, 0, 0)
			part.Color = Color3.fromRGB(105, 221, 210)
			part.Material = Enum.Material.Neon
			part.Transparency = 0.65
			part.Parent = folder
			self.Active[id] = { Part = part, At = now, Kind = "echo", Duration = 0.22 }
		end
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
		for model, echo in self.Echoes do
			if not model.Parent or echo.Left <= 0 then
				self.Echoes[model] = nil
			elseif now >= echo.Next then
				self:echo(model, now)
				echo.Left -= 1
				echo.Next = now + 0.055
			end
		end
		for model, fade in self.Fades do
			if now >= fade.Ends or not model.Parent then
				for part, original in fade.Parts do
					if part.Parent then
						part.LocalTransparencyModifier = original
					end
				end
				self.Fades[model] = nil
			end
		end
		for id, d in self.Active do
			local age = now - d.At
			if d.Kind == "echo" then
				d.Part.Transparency = 0.65 + 0.35 * math.clamp(age / d.Duration, 0, 1)
				if age >= d.Duration then
					Budget.release(self.Budget, id)
					d.Part.Parent = nil
					table.insert(self.Free, d.Part)
					self.Active[id] = nil
				end
				continue
			end
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
		for _, fade in self.Fades do
			for part, original in fade.Parts do
				if part.Parent then
					part.LocalTransparencyModifier = original
				end
			end
		end
		self.Fades = {}
		self.Echoes = {}
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
