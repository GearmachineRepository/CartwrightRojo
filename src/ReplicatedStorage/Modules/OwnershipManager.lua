--!strict

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))

local OwnershipManager = {}

type OwnershipData = {
	LastInteractionTime: number,
	OwnerId: number?
}

local TrackedObjects: {[Instance]: OwnershipData} = {}

local function IsOnCart(Object: Instance): boolean
	if Object:GetAttribute("SnappedToGrid") then
		return true
	end
	
	local Node = Object.Parent
	while Node and Node ~= workspace do
		if Node:IsA("Model") and Node:GetAttribute("Type") == "Cart" then
			return true
		end
		Node = Node.Parent
	end
	
	return false
end

local function IsBeingUsed(Object: Instance): boolean
	if Object:GetAttribute("BeingDragged") then
		return true
	end
	
	if Object:GetAttribute("InUse") then
		return true
	end
	
	if Object:GetAttribute("Interacting") then
		return true
	end
	
	if Object:GetAttribute("Equipped") then
		return true
	end
	
	return false
end

local function ShouldUnown(Object: Instance, Data: OwnershipData): boolean
	local CurrentTime = tick()
	local TimeSinceInteraction = CurrentTime - Data.LastInteractionTime
	
	if TimeSinceInteraction < GeneralUtil.OWNERSHIP_TIMEOUT then
		return false
	end
	
	if IsOnCart(Object) then
		return false
	end
	
	if IsBeingUsed(Object) then
		return false
	end
	
	return true
end

function OwnershipManager.TrackOwnership(Object: Instance, OwnerId: number): ()
	TrackedObjects[Object] = {
		LastInteractionTime = tick(),
		OwnerId = OwnerId
	}
end

function OwnershipManager.UpdateInteractionTime(Object: Instance): ()
	local Data = TrackedObjects[Object]
	if Data then
		Data.LastInteractionTime = tick()
	end
end

function OwnershipManager.RemoveOwnership(Object: Instance): ()
	Object:SetAttribute("Owner", nil)
	TrackedObjects[Object] = nil
end

function OwnershipManager.StopTracking(Object: Instance): ()
	TrackedObjects[Object] = nil
end

local function CheckOwnershipTimeouts(): ()
	for Object, Data in pairs(TrackedObjects) do
		if not Object.Parent then
			TrackedObjects[Object] = nil
			continue
		end
		
		if ShouldUnown(Object, Data) then
			OwnershipManager.RemoveOwnership(Object)
		end
	end
end

local LastCheckTime = 0
RunService.Heartbeat:Connect(function()
	local CurrentTime = tick()
	if CurrentTime - LastCheckTime >= GeneralUtil.CHECK_INTERVAL then
		LastCheckTime = CurrentTime
		CheckOwnershipTimeouts()
	end
end)

return OwnershipManager