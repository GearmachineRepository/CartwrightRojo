--!strict
local CollectionService = game:GetService("CollectionService")

local THEFT_ZONE_TAG = "TheftZone"

local function SetupZoneVisual(Part: BasePart)
	-- local IsActive = Part:GetAttribute("ZoneActive")
	-- if IsActive == nil then
	-- 	Part:SetAttribute("ZoneActive", true)
	-- end

	Part.Transparency = 0.8
	Part.CanCollide = false
	Part.CanQuery = false
	Part.CanTouch = true
	Part.Color = Color3.fromRGB(255, 100, 100)
end

CollectionService:GetInstanceAddedSignal(THEFT_ZONE_TAG):Connect(function(Instance)
	if Instance:IsA("BasePart") then
		SetupZoneVisual(Instance)
	end
end)

for _, Part in ipairs(CollectionService:GetTagged(THEFT_ZONE_TAG)) do
	if Part:IsA("BasePart") then
		SetupZoneVisual(Part)
	end
end
