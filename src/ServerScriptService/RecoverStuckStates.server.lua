--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))

local STUCK_STATE_ATTRIBUTES = {
	"BeingDragged",
	"Interacting",
	"BrewingPlayer",
	"DraggedBy"
}

local function RecoverStuckStates()
	local recoveredCount = 0

	for _, object in ipairs(workspace:GetDescendants()) do
		-- Check if object has any stuck state attributes
		local isStuck = false

		for _, attrName in ipairs(STUCK_STATE_ATTRIBUTES) do
			if object:GetAttribute(attrName) then
				isStuck = true
				break
			end
		end

		if isStuck then
			-- Force object back to Idle state
			ObjectStateManager.ForceIdle(object)
			recoveredCount += 1

			print(string.format("[StateRecovery] Recovered: %s", object:GetFullName()))
		end
	end

	print(string.format("[StateRecovery] Recovery complete. Fixed %d objects.", recoveredCount))
end

-- Run on server start
task.wait(2) -- Wait for other systems to initialize
RecoverStuckStates()