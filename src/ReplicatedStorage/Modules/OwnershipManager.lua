--!strict
local OwnershipManager = {}

--local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local OWNERSHIP_TIMEOUT = 30
local CHECK_INTERVAL = 2

type OwnershipData = {
	LastInteractionTime: number,
	OwnerId: number?
}

local TrackedObjects: {[Instance]: OwnershipData} = {}

local function IsOnCart(object: Instance): boolean
	if object:GetAttribute("SnappedToGrid") then
		return true
	end
	
	local node = object.Parent
	while node and node ~= workspace do
		if node:IsA("Model") and node:GetAttribute("Type") == "Cart" then
			return true
		end
		node = node.Parent
	end
	
	return false
end

local function IsBeingUsed(object: Instance): boolean
	if object:GetAttribute("BeingDragged") then
		return true
	end
	
	if object:GetAttribute("InUse") then
		return true
	end
	
	if object:GetAttribute("Interacting") then
		return true
	end
	
	if object:GetAttribute("Equipped") then
		return true
	end
	
	return false
end

local function ShouldUnown(object: Instance, data: OwnershipData): boolean
	local currentTime = tick()
	local timeSinceInteraction = currentTime - data.LastInteractionTime
	
	if timeSinceInteraction < OWNERSHIP_TIMEOUT then
		return false
	end
	
	if IsOnCart(object) then
		return false
	end
	
	if IsBeingUsed(object) then
		return false
	end
	
	return true
end

function OwnershipManager.TrackOwnership(object: Instance, ownerId: number): ()
	TrackedObjects[object] = {
		LastInteractionTime = tick(),
		OwnerId = ownerId
	}
end

function OwnershipManager.UpdateInteractionTime(object: Instance): ()
	local data = TrackedObjects[object]
	if data then
		data.LastInteractionTime = tick()
	end
end

function OwnershipManager.RemoveOwnership(object: Instance): ()
	object:SetAttribute("Owner", nil)
	TrackedObjects[object] = nil
end

function OwnershipManager.StopTracking(object: Instance): ()
	TrackedObjects[object] = nil
end

local function CheckOwnershipTimeouts(): ()
	for object, data in pairs(TrackedObjects) do
		if not object.Parent then
			TrackedObjects[object] = nil
			continue
		end
		
		if ShouldUnown(object, data) then
			OwnershipManager.RemoveOwnership(object)
		end
	end
end

local LastCheckTime = 0
RunService.Heartbeat:Connect(function()
	local currentTime = tick()
	if currentTime - LastCheckTime >= CHECK_INTERVAL then
		LastCheckTime = currentTime
		CheckOwnershipTimeouts()
	end
end)

return OwnershipManager