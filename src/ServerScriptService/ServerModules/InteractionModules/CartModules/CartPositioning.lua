--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))

local CartPositioning = {}

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude

function CartPositioning.PositionAtGroundLevel(Cart: Model, WheelDiameter: number): ()
	if not Cart.PrimaryPart then 
		return 
	end

	RayParams.FilterDescendantsInstances = {
		Cart, 
		workspace.Characters, 
		workspace.Draggables, 
		workspace.Interactables, 
		workspace.NPC
	}

	local RayOrigin = Cart.PrimaryPart.Position + Vector3.new(0, 5, 0)
	local RayResult = workspace:Raycast(RayOrigin, Vector3.new(0, -50, 0), RayParams)

	if RayResult then
		local _, Size = Cart:GetBoundingBox()
		
		local WheelRadius = (WheelDiameter / 2) - 0.3
		local TargetY = RayResult.Position.Y + WheelRadius + (Size.Y / 2)
		local CurrentY = Cart.PrimaryPart.Position.Y
		local YOffset = TargetY - CurrentY
		
		Cart:PivotTo(Cart:GetPivot() * CFrame.new(0, YOffset, 0))
	end
end

function CartPositioning.GetAverageWheelDiameter(Cart: Model): number
	local Diameters = {}

	for _, Descendant in ipairs(Cart:GetDescendants()) do
		if Descendant:IsA("Model") and Descendant:GetAttribute("PartType") == "Wheel" then
			local _, Size = Descendant:GetBoundingBox()
			local Diameter = math.max(Size.X, Size.Z)
			table.insert(Diameters, Diameter)
		end
	end

	if #Diameters == 0 then
		return 4
	end

	return GeneralUtil.GetAverage(Diameters)
end

return CartPositioning