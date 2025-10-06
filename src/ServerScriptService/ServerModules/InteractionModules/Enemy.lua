--!strict
local Item = {}

function Item.StateAFunction(Player: Player, Object: Instance, _: any): ()
	if not Object:IsA("Model") then return end

	Object:SetAttribute("Owner", Player.UserId)
	Object:SetAttribute("InteractedWith", true)
end

function Item.StateBFunction(Player: Player, Object: Instance, _: any): ()
	if not Object:IsA("Model") then return end

	Object:SetAttribute("Owner", Player.UserId)
	Object:SetAttribute("InteractedWith", true)
end

return Item