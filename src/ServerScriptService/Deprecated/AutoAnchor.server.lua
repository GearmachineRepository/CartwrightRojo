local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

-- Constants
local DRAG_TAG: string = "Drag"
local AUTO_ANCHOR_DELAY: number = 2
local STILLNESS_THRESHOLD: number = 0.1
local CHECK_INTERVAL: number = 0.1 -- Check every 100ms instead of every frame

-- Centralized tracking
local ObjectsToMonitor: {[Instance]: {StillTime: number, PhysicsPart: BasePart}} = {}
local AttributeConnections: {[Instance]: RBXScriptConnection} = {}
local LastCheckTime: number = 0

-- Optimized monitoring function
local function CheckForStillObjects()
	local currentTime = tick()
	if currentTime - LastCheckTime < CHECK_INTERVAL then return end

	local deltaTime = currentTime - LastCheckTime
	LastCheckTime = currentTime

	for Target: Instance, Data: {StillTime: number, PhysicsPart: BasePart} in pairs(ObjectsToMonitor) do
		-- Remove if destroyed
		if not Target.Parent then
			ObjectsToMonitor[Target] = nil
			continue
		end

		-- Remove if being dragged
		if Target:GetAttribute("BeingDragged") then
			ObjectsToMonitor[Target] = nil
			continue
		end

		-- Check stillness
		if Data.PhysicsPart.AssemblyLinearVelocity.Magnitude < STILLNESS_THRESHOLD then
			Data.StillTime += deltaTime
			if Data.StillTime >= AUTO_ANCHOR_DELAY then
				Data.PhysicsPart.Anchored = true
				Target:SetAttribute("AutoAnchored", true)
				ObjectsToMonitor[Target] = nil
			end
		else
			Data.StillTime = 0
		end
	end
end

-- Handle drag state changes
local function OnDragStateChanged(Target: Instance)
	local BeingDragged = Target:GetAttribute("BeingDragged")

	if BeingDragged == nil then
		-- Start monitoring when drag ends
		local PhysicsPart: BasePart? = Target:IsA("Model") and (Target :: Model).PrimaryPart or (Target :: BasePart)
		if PhysicsPart and not PhysicsPart.Anchored then
			ObjectsToMonitor[Target] = {StillTime = 0, PhysicsPart = PhysicsPart}
		end
	elseif BeingDragged == true then
		-- Stop monitoring and unanchor when drag starts
		ObjectsToMonitor[Target] = nil
		if Target:GetAttribute("AutoAnchored") then
			Target:SetAttribute("AutoAnchored", nil)
		end
	end
end

-- Setup connections for existing objects
for _, Target: Instance in pairs(CollectionService:GetTagged(DRAG_TAG)) do
	AttributeConnections[Target] = Target.AttributeChanged:Connect(function(attributeName)
		if attributeName == "BeingDragged" then
			OnDragStateChanged(Target)
		end
	end)
end

-- Setup connections for new objects
CollectionService:GetInstanceAddedSignal(DRAG_TAG):Connect(function(Target: Instance)
	AttributeConnections[Target] = Target.AttributeChanged:Connect(function(attributeName)
		if attributeName == "BeingDragged" then
			OnDragStateChanged(Target)
		end
	end)
end)

-- Cleanup connections when objects are removed
CollectionService:GetInstanceRemovedSignal(DRAG_TAG):Connect(function(Target: Instance)
	if AttributeConnections[Target] then
		AttributeConnections[Target]:Disconnect()
		AttributeConnections[Target] = nil
	end
	ObjectsToMonitor[Target] = nil
end)


-- Start the monitoring loop
RunService.Heartbeat:Connect(CheckForStillObjects)