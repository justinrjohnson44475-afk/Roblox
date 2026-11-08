--!strict
local fs = require("@lune/fs")
local R = require("@lune/roblox")
for _, path in { "build/Ascension-Signature.rbxl", "build/Ascension-Signature.rbxlx" } do
	local place = R.deserializePlace(fs.readFile(path))
	local shared = place:GetService("ReplicatedStorage").Shared
	assert(shared:GetAttribute("AscensionEnabled") == true)
	local source = place:GetService("ReplicatedStorage").AscensionSource
	assert(#source.SourceClips:GetChildren() == 30)
	assert(source.R15CollisionProxy.PrimaryPart)
	assert(place:GetService("Workspace"):FindFirstChild("SignatureArena"))
	local count = 0
	for _, obj in place:GetDescendants() do
		if obj:IsA("LuaSourceContainer") then
			count += 1
			assert(#obj.Source > 0)
		end
	end
	print(
		"PASS "
			.. path
			.. ": "
			.. count
			.. " scripts, 30 clips, diagnostic R15 rig and signature arena. No engine execution."
	)
end
