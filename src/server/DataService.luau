--!strict
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Config = require(Shared.Config)
local Profile = require(Shared.Profile)
local DataService = {}
local entries = {}
local memoryOnly = RunService:IsStudio() and not Config.EnableStudioDataStore
local store = if memoryOnly then nil else DataStoreService:GetDataStore(Config.DataStoreName)
local session = game.JobId .. ":" .. HttpService:GenerateGUID(false)

function DataService.load(player)
	if memoryOnly then
		entries[player] = { Data = Profile.new(), Ready = true, Saving = false, LeaseUntil = math.huge }
		return true
	end
	local result
	local ok, err = pcall(function()
		result = store:UpdateAsync("player_" .. player.UserId, function(old)
			if old ~= nil then
				assert(type(old) == "table" and type(old.Data) == "table", "Invalid stored envelope")
				if old.Owner and old.Owner ~= session and (old.LeaseUntil or 0) > os.time() then
					error("Profile is active in another server; retry shortly")
				end
			end
			local data = Profile.decode(if old then old.Data else nil)
			return { Data = data, Owner = session, LeaseUntil = os.time() + Config.LeaseSeconds }
		end)
	end)
	if not ok or not result then
		warn("Riftwake profile load failed:", err)
		return false
	end
	entries[player] =
		{ Data = Profile.decode(result.Data), Ready = true, Saving = false, LeaseUntil = result.LeaseUntil }
	return true
end

function DataService.get(player)
	local entry = entries[player]
	if not entry or not entry.Ready then
		return nil
	end
	if entry.LeaseUntil <= os.time() + 10 then
		entry.Ready = false
		player:Kick("Your save connection expired. Please rejoin to protect your progress.")
		return nil
	end
	return entry.Data
end

function DataService.mode(): string
	return if memoryOnly then "Studio preview — progress is not saved" else "Persistent profile"
end

function DataService.save(player, release: boolean): boolean
	local entry = entries[player]
	if not entry then
		return true
	end
	-- Serialize autosave and close; close snapshots only after the previous write returns.
	local deadline = os.clock() + 12
	while entry.Saving and os.clock() < deadline do
		task.wait(0.1)
	end
	if entry.Saving then
		return false
	end
	entry.Saving = true
	if release then
		entry.Ready = false
	end
	if memoryOnly then
		entry.Saving = false
		if release then
			entries[player] = nil
		end
		return true
	end
	local snapshot = Profile.copy(entry.Data)
	local lostLease = false
	local ok = false
	for attempt = 1, 3 do
		local result
		local success, err = pcall(function()
			result = store:UpdateAsync("player_" .. player.UserId, function(old)
				if not old or old.Owner ~= session then
					lostLease = true
					return nil -- Cancel; never overwrite a newer session.
				end
				return {
					Data = snapshot,
					Owner = if release then nil else session,
					LeaseUntil = if release then 0 else os.time() + Config.LeaseSeconds,
				}
			end)
		end)
		if success and result and not lostLease then
			ok = true
			entry.LeaseUntil = result.LeaseUntil
			player:SetAttribute("SaveWarning", false)
			break
		end
		warn("Riftwake save failed", player.UserId, attempt, err)
		if lostLease then
			break
		end
		if attempt < 3 then
			task.wait(attempt)
		end
	end
	entry.Saving = false
	if not ok then
		player:SetAttribute("SaveWarning", true)
		if lostLease then
			entry.Ready = false
			player:Kick("This profile opened elsewhere. Please rejoin.")
		end
	end
	if release then
		entries[player] = nil
	end
	return ok
end
return DataService
