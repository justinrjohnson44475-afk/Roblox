--!strict
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local function inspect(path)
	local place = roblox.deserializePlace(fs.readFile(path))
	local function child(parent, name, class)
		local item = parent:FindFirstChild(name)
		assert(item and item:IsA(class), "Missing " .. name .. " in " .. path)
		return item
	end
	local storage = child(place, "ReplicatedStorage", "ReplicatedStorage")
	local shared = child(storage, "Shared", "Folder")
	child(shared, "Config", "ModuleScript")
	child(shared, "Profile", "ModuleScript")
	local server = child(child(place, "ServerScriptService", "ServerScriptService"), "Server", "Folder")
	local entry = child(server, "Main", "Script")
	assert(#entry.Source > 1000 and not entry.Disabled)
	child(server, "DataService", "ModuleScript")
	local client = child(
		child(child(place, "StarterPlayer", "StarterPlayer"), "StarterPlayerScripts", "StarterPlayerScripts"),
		"Client",
		"Folder"
	)
	child(client, "Main", "LocalScript")
	local world = child(place, "Workspace", "Workspace")
	assert(child(world, "HarborFoundation", "Part").Anchored)
	child(world, "Spawn", "SpawnLocation")
	local scripts = 0
	for _, instance in place:GetDescendants() do
		if instance:IsA("LuaSourceContainer") then
			scripts += 1
			assert(#instance.Source > 0)
		end
	end
	assert(scripts == 12, "Unexpected script count: " .. scripts)
	print(string.format("PASS %s: %d nonempty scripts, expected services, floor and spawn", path, scripts))
end
inspect("build/Harborlight.rbxl")
inspect("build/Harborlight.rbxlx")
print("Structural inspection only. No Roblox engine execution occurred.")
