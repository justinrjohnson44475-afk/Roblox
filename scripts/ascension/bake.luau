--!strict
-- Source preview contains diagnostic collision proxies, never substitutes for imported hero meshes.
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local R = require("@lune/roblox")
local I, V, C, E = R.Instance, R.Vector3, R.CFrame, R.Enum
local data = serde.decode("json", fs.readFile("assets/ascension/animations/choreography.json"))
local library = I.new("Folder")
library.Name = "SourceClips"
local priorities = {
	idle = E.AnimationPriority.Idle,
	movement = E.AnimationPriority.Movement,
	action = E.AnimationPriority.Action,
}
for name, clip in data.clips do
	local seq = I.new("KeyframeSequence")
	seq.Name = name
	seq.Loop = clip.loop
	seq.Priority = priorities[string.lower(clip.priority)] or E.AnimationPriority.Action
	seq.Parent = library
	for _, frame in clip.frames do
		local key = I.new("Keyframe")
		key.Time = frame.time
		key.Parent = seq
		local poses = {}
		local root = I.new("Pose")
		root.Name = "HumanoidRootPart"
		root.Weight = 1
		root.Parent = key
		poses.HumanoidRootPart = root
		local function add(bone)
			if poses[bone] then
				return poses[bone]
			end
			local def = data.bones[bone]
			local pose = I.new("Pose")
			pose.Name = bone
			pose.Weight = 1
			pose.CFrame = C.new(unpack(frame.poses[bone]))
			pose.EasingStyle = E.PoseEasingStyle.Linear
			pose.Parent = add(def.parent)
			poses[bone] = pose
			return pose
		end
		for bone in frame.poses do
			add(bone)
		end
		for marker, t in clip.markers do
			if math.abs(t - frame.time) < 0.00001 then
				local m = I.new("KeyframeMarker")
				m.Name = marker
				m.Parent = key
			end
		end
	end
end
fs.writeFile("assets/ascension/animations/SourceClips.rbxmx", R.serializeModel({ library }, true))
local model = I.new("Model")
model.Name = "R15CollisionProxy"
local parts = {}
local sizes = {
	HumanoidRootPart = { 2, 2, 1 },
	LowerTorso = { 1.5, 0.5, 0.9 },
	UpperTorso = { 1.9, 1.1, 1 },
	Head = { 1.1, 1.25, 1 },
	RightUpperArm = { 0.7, 0.8, 0.7 },
	RightLowerArm = { 0.6, 0.7, 0.6 },
	RightHand = { 0.55, 0.35, 0.6 },
	LeftUpperArm = { 0.7, 0.8, 0.7 },
	LeftLowerArm = { 0.6, 0.7, 0.6 },
	LeftHand = { 0.55, 0.35, 0.6 },
	RightUpperLeg = { 0.8, 1.1, 0.8 },
	RightLowerLeg = { 0.7, 1.1, 0.7 },
	RightFoot = { 0.75, 0.45, 1.1 },
	LeftUpperLeg = { 0.8, 1.1, 0.8 },
	LeftLowerLeg = { 0.7, 1.1, 0.7 },
	LeftFoot = { 0.75, 0.45, 1.1 },
}
for bone, def in data.bones do
	local p = I.new("Part")
	p.Name = bone
	p.Size = V.new(unpack(sizes[bone]))
	p.CFrame = C.new(V.new(unpack(def.center)))
	p.Anchored = false
	p.CanCollide = bone == "HumanoidRootPart"
	p.Massless = bone ~= "HumanoidRootPart"
	p.Transparency = if bone == "HumanoidRootPart" then 1 else 0.15
	p.Color = R.Color3.fromRGB(90, 110, 125)
	p.Parent = model
	parts[bone] = p
end
for bone, def in data.bones do
	if def.parent then
		local joint = I.new("Motor6D")
		joint.Name = bone .. "Joint"
		joint.Part0 = parts[def.parent]
		joint.Part1 = parts[bone]
		joint.C0 = C.new(V.new(unpack(def.joint)) - V.new(unpack(data.bones[def.parent].center)))
		joint.C1 = C.new(V.new(unpack(def.joint)) - V.new(unpack(def.center)))
		joint.Parent = parts[def.parent]
	end
end
local hum = I.new("Humanoid")
hum.RigType = E.HumanoidRigType.R15
hum.HipHeight = 2
hum.Parent = model
local animator = I.new("Animator")
animator.Parent = hum
model.PrimaryPart = parts.HumanoidRootPart
local blade = I.new("Part")
blade.Name = "RelicBladeProxy"
blade.Size = V.new(0.3, 0.3, 3.7)
blade.Color = R.Color3.fromRGB(70, 230, 190)
blade.CanCollide = false
blade.Massless = true
blade.CFrame = parts.RightHand.CFrame * C.new(0, 0, -2.1)
blade.Parent = model
local weld = I.new("WeldConstraint")
weld.Part0 = parts.RightHand
weld.Part1 = blade
weld.Parent = blade
for name, z in { BladeBase = 1.85, BladeTip = -1.85 } do
	local a = I.new("Attachment")
	a.Name = name
	a.Position = V.new(0, 0, z)
	a.Parent = blade
end
fs.writeFile("assets/ascension/R15CollisionProxy.rbxmx", R.serializeModel({ model }, true))
-- Small signature arena, intentionally not the later 480x480 Verdant flagship.
local arena = I.new("Model")
arena.Name = "SignatureArena"
local function part(name, size, pos, color, material)
	local p = I.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = C.new(pos)
	p.Anchored = true
	p.Color = R.Color3.fromRGB(unpack(color))
	p.Material = material or E.Material.Slate
	p.Parent = arena
	return p
end
part("Foundation", V.new(156, 6, 156), V.new(0, -3, 0), { 55, 70, 65 })
part("SanctuaryFloor", V.new(48, 2, 40), V.new(0, 1, 52), { 95, 112, 98 })
for i = 0, 11 do
	local a = i * math.pi / 6
	local x, z = math.sin(a) * 65, math.cos(a) * 65
	local p =
		part("BrokenPillar" .. i, V.new(5, 14 + (i % 3) * 4, 5), V.new(x, 7 + (i % 3) * 2, z), { 76, 96, 82 })
	p.CFrame *= C.Angles(0, a, 0)
	part(
		"BronzeCapital" .. i,
		V.new(7, 1, 7),
		V.new(x, 14 + (i % 3) * 4, z),
		{ 125, 101, 58 },
		E.Material.Metal
	)
end
for i = -2, 2 do
	part("ArrivalStep" .. i, V.new(22 + i * 2, 1, 5), V.new(0, 1 + i * 0.3, 34 + i * 5), { 100, 116, 102 })
end
for _, x in { -77, 77 } do
	part("Boundary", V.new(2, 18, 156), V.new(x, 7, 0), { 40, 62, 52 })
end
for _, z in { -77, 77 } do
	part("Boundary", V.new(156, 18, 2), V.new(0, 7, z), { 40, 62, 52 })
end
-- Side training alcove leaves the central Warden floor and its approved slate intact.
part("WallRunPracticeWest", V.new(2, 16, 36), V.new(42, 8, 32), { 102, 111, 111 }, E.Material.Concrete)
part("WallRunPracticeEast", V.new(2, 16, 36), V.new(66, 8, 32), { 94, 105, 107 }, E.Material.Concrete)
for _, x in { 42, 66 } do
	part("UrbanLintel", V.new(3, 1, 38), V.new(x, 16.5, 32), { 113, 102, 76 }, E.Material.Metal)
	for z = 20, 44, 12 do
		part("UrbanFacadeInset", V.new(2.1, 4, 3), V.new(x, 10, z), { 37, 61, 65 }, E.Material.Slate)
	end
end
part("DuneMaterialStudy", V.new(14, 0.16, 14), V.new(-52, 0.08, 58), { 181, 151, 96 }, E.Material.Sand)
for _, x in { -64, -43 } do
	local trunk = part("JungleTreeTrunk", V.new(12, 2, 2), V.new(x, 6, 30), { 84, 68, 49 }, E.Material.Wood)
	trunk.Shape = E.PartType.Cylinder
	trunk.CFrame *= C.Angles(0, 0, math.pi / 2)
	local leaf = part("JungleCanopy", V.new(15, 7, 13), V.new(x, 14, 30), { 53, 95, 63 }, E.Material.Grass)
	leaf.Shape = E.PartType.Ball
	leaf.CanCollide = false
end
local previous = V.new(-64, 12, 30)
for i = 1, 16 do
	local t = i / 16
	local nextPoint = V.new(-64 + 21 * t, 12 - math.sin(t * math.pi) * 5, 30 + math.sin(t * math.pi) * 1.5)
	local delta = nextPoint - previous
	local vine = part(
		"HangingVine",
		V.new(delta.Magnitude, 0.22, 0.22),
		(previous + nextPoint) / 2,
		{ 46, 91, 54 },
		E.Material.Grass
	)
	vine.Shape = E.PartType.Cylinder
	vine.CFrame = C.lookAt((previous + nextPoint) / 2, nextPoint) * C.Angles(0, math.pi / 2, 0)
	vine.CanCollide = false
	vine.CanTouch = false
	previous = nextPoint
end
fs.writeFile("assets/ascension/SignatureArena.rbxmx", R.serializeModel({ arena }, true))
-- Canonical blade points measured from the exported armature, sampled by server time.
local samples = { Version = 1, Clips = {} }
for name, clip in data.clips do
	samples.Clips[name] = { Duration = clip.duration, Samples = clip.sweep }
end
local encoded = serde.encode("json", samples)
fs.writeFile(
	"src/shared/Ascension/Choreography.luau",
	'--!strict\n-- Generated by scripts/ascension/bake.luau; measured source rig blade trajectories.\nlocal HttpService = game:GetService("HttpService")\nreturn HttpService:JSONDecode([=['
		.. encoded
		.. "]=])\n"
)
print(
	"Baked 33 source clips, diagnostic R15 rig, signature arena and measured weapon samples; engine unverified."
)
