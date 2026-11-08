--!strict
local Service = game:GetService("AnalyticsService")
local RunService = game:GetService("RunService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Analytics = {}
local allowed = { FirstContribution = true, RepairCompleted = true }
function Analytics.record(player, event: string)
	if not Config.EnableAnalytics or RunService:IsStudio() or not allowed[event] then
		return
	end
	local ok, err = pcall(function()
		Service:LogCustomEvent(player, event, 1)
	end)
	if not ok then
		warn("Harborlight analytics unavailable:", err)
	end
end
return Analytics
