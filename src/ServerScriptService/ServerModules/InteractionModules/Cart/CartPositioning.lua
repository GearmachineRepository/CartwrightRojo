--!strict
local CartPositioning = {}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- Position cart at correct ground height based on wheel diameter
function CartPositioning.PositionAtGroundLevel(cart: Model, wheelDiameter: number): ()
	if not cart.PrimaryPart then return end

	rayParams.FilterDescendantsInstances = {cart, workspace.Characters, workspace.Draggables, workspace.Interactables, workspace.NPC}


	local rayOrigin = cart.PrimaryPart.Position + Vector3.new(0, 5, 0)
	local rayResult = workspace:Raycast(rayOrigin, Vector3.new(0, -50, 0), rayParams)

	if rayResult then
		local Bounds, Size = cart:GetBoundingBox()
		
		local wheelRadius = (wheelDiameter/2) - 0.3
		local targetY = rayResult.Position.Y + wheelRadius + (Size.Y/2)
		local currentY = cart.PrimaryPart.Position.Y
		local yOffset = targetY - currentY
		
		-- Move cart to correct height
		cart:PivotTo(cart:GetPivot() * CFrame.new(0, yOffset, 0))
	end
end

-- Get average wheel diameter from installed wheels
function CartPositioning.GetAverageWheelDiameter(cart: Model): number
	local diameters = {}

	for _, descendant in ipairs(cart:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("PartType") == "Wheel" then
			local _, size = descendant:GetBoundingBox()
			local diameter = math.max(size.X, size.Z)
			table.insert(diameters, diameter)
		end
	end

	-- If no wheels found, return default
	if #diameters == 0 then
		return 4
	end

	-- Calculate average
	local sum = 0
	for _, diameter in ipairs(diameters) do
		sum += diameter
	end
	return sum / #diameters
end

return CartPositioning