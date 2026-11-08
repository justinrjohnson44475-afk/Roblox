--!strict
local MarketplaceService = game:GetService("MarketplaceService")
local Config = require(game:GetService("ReplicatedStorage").Shared.Config)
local Purchases = {}
local owned = {}
function Purchases.refresh(player)
	if Config.SupporterPassId <= 0 then
		return
	end
	local ok, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, Config.SupporterPassId)
	end)
	if ok and player.Parent then
		owned[player] = result
		player:SetAttribute("HarborSupporter", result == true)
	end
end
function Purchases.prompt(player)
	if Config.SupporterPassId <= 0 then
		return false, "Robux purchases are not enabled in this build"
	end
	if owned[player] then
		return false, "You already own the ocean rig trim"
	end
	local ok = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, Config.SupporterPassId)
	end)
	return ok,
		if ok
			then "Check Roblox’s purchase prompt for the current price"
			else "Purchase service is unavailable"
end
function Purchases.remove(player)
	owned[player] = nil
end
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
	if passId == Config.SupporterPassId and purchased then
		-- Do not trust a client notification; requery Roblox ownership.
		task.spawn(Purchases.refresh, player)
	end
end)
return Purchases
