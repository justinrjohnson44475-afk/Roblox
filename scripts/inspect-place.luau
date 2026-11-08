--!strict
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local function sourceCount(path)
	local count = 0
	for _, name in fs.readDir(path) do
		local full = path .. "/" .. name
		if fs.isDir(full) then
			count += sourceCount(full)
		elseif name:match("%.luau$") then
			count += 1
		end
	end
	return count
end
local function inspect(path)
	local place = roblox.deserializePlace(fs.readFile(path))
	local function child(parent, name, class)
		local item = parent:FindFirstChild(name)
		assert(item and item:IsA(class), "Missing " .. name .. " in " .. path)
		return item
	end
	local shared = child(child(place, "ReplicatedStorage", "ReplicatedStorage"), "Shared", "Folder")
	for _, name in { "Config", "Profile", "Combat", "Progression", "EnemyAI", "Authority" } do
		child(shared, name, "ModuleScript")
	end
	local server = child(child(place, "ServerScriptService", "ServerScriptService"), "Server", "Folder")
	local entry = child(server, "Main", "Script")
	assert(#entry.Source > 10000 and not entry.Disabled)
	child(server, "DataService", "ModuleScript")
	child(server, "Appearance", "ModuleScript")
	local client = child(
		child(child(place, "StarterPlayer", "StarterPlayer"), "StarterPlayerScripts", "StarterPlayerScripts"),
		"Client",
		"Folder"
	)
	child(client, "Main", "LocalScript")
	child(client, "Effects", "ModuleScript")
	local workspace = child(place, "Workspace", "Workspace")
	local map = child(workspace, "RiftwakeWorld", "Folder")
	for _, id in { "hub", "verdant", "ember", "astral" } do
		child(child(map, id, "Folder"), "Ground", "Part")
	end
	child(workspace, "Spawn", "SpawnLocation")
	local geometry = 0
	for _, item in map:GetDescendants() do
		assert(not item:IsA("LuaSourceContainer"), "Unexpected script embedded in generated world")
		if item:IsA("BasePart") then
			geometry += 1
			assert(item.Anchored)
		end
	end
	assert(geometry > 600)
	local scripts = 0
	for _, instance in place:GetDescendants() do
		if instance:IsA("LuaSourceContainer") then
			scripts += 1
			assert(#instance.Source > 0)
		end
	end
	assert(scripts == sourceCount("src"), "Unexpected script count")
	print(
		string.format(
			"PASS %s: %d nonempty scripts, %d baked anchored parts, four regions and spawn",
			path,
			scripts,
			geometry
		)
	)
end
inspect("build/Riftwake.rbxl")
inspect("build/Riftwake.rbxlx")
print("Structural inspection only. No Roblox engine execution occurred.")
