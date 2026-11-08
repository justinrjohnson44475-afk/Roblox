--!strict
return table.freeze({
	Capacity = 5,
	TokensPerSupply = 2,
	PickupCooldown = 8,
	InteractionDistance = 14,
	ShiftSeconds = 240,
	CelebrationSeconds = 12,
	Projects = {
		{ Id = "pier", Name = "Mend the pier", Required = 8 },
		{ Id = "greenhouse", Name = "Restore the greenhouse", Required = 12 },
		{ Id = "beacon", Name = "Relight the beacon", Required = 16 },
	},
	Cosmetics = {
		amber = { Name = "Amber", Cost = 0, RGB = { 255, 190, 90 } },
		sea = { Name = "Sea-glass", Cost = 30, RGB = { 80, 230, 195 } },
		violet = { Name = "Violet", Cost = 60, RGB = { 190, 150, 255 } },
	},
	SupporterPassId = 0, -- Configure only after private purchase testing and offer approval.
	EnableAnalytics = false,
	EnableStudioDataStore = false, -- Use a separate test universe before changing this.
	SaveSeconds = 45,
	LeaseSeconds = 180,
})
