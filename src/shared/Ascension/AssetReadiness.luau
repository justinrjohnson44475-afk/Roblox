--!strict
local Readiness = {}
function Readiness.evaluate(manifest, studioPreview)
	local missing = {}
	local required = 0
	if type(manifest) ~= "table" or manifest.Version ~= 1 or type(manifest.Assets) ~= "table" then
		return { Ready = false, Missing = { "invalid-manifest" }, Mode = "blocked" }
	end
	for key, asset in manifest.Assets do
		local valid = type(asset.RobloxId) == "number"
			and asset.RobloxId > 0
			and asset.RobloxId % 1 == 0
			and type(asset.Owner) == "string"
			and #asset.Owner > 0
			and asset.Owner ~= "UNASSIGNED_ROBLOX_CREATOR"
			and type(asset.EngineEvidence) == "string"
			and #asset.EngineEvidence > 0
			and asset.Status == "engine-validated"
			and asset.LicenseVerified == true
		if asset.Required then
			required += 1
		end
		if asset.Required and not valid then
			table.insert(missing, key)
		end
	end
	if required == 0 then
		table.insert(missing, "no-required-assets")
	end
	table.sort(missing)
	return {
		Ready = #missing == 0,
		Missing = missing,
		Mode = if #missing == 0
			then "configured-playtest"
			elseif studioPreview then "studio-source-preview"
			else "blocked",
	}
end
return Readiness
