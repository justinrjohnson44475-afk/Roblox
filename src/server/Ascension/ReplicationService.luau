--!strict
local Replication = {}
function Replication.new(parent)
	local folder = Instance.new("Folder")
	folder.Name = "AscensionRemotes"
	folder.Parent = parent
	local self = { Folder = folder, Events = {} }
	for _, name in { "Request", "State", "Combat", "Gate" } do
		local r = Instance.new("RemoteEvent")
		r.Name = name
		r.Parent = folder
		self.Events[name] = r
	end
	function self:combat(players, event)
		for _, player in players do
			if player.Parent then
				self.Events.Combat:FireClient(player, event)
			end
		end
	end
	function self:state(player, value)
		if player.Parent then
			self.Events.State:FireClient(player, value)
		end
	end
	function self:destroy()
		self.Folder:Destroy()
	end
	return self
end
return Replication
