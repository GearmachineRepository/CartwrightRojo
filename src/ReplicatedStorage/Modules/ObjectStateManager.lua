--!strict
local ObjectStateManager = {}

-- Valid state transitions
local VALID_TRANSITIONS = {
	Idle = {"BeingDragged", "SnappedToGrid", "Interacting", "InUse", "Equipped"},
	BeingDragged = {"Idle", "SnappedToGrid", "InUse"},
	SnappedToGrid = {"BeingDragged", "Idle"},
	Interacting = {"Idle"},
	InUse = {"Idle"},
	Equipped = {"Idle"}
}

-- State change callbacks
local StateChangeCallbacks: {[Instance]: {(string, string) -> ()}} = {}

-- Get current state of an object
local function GetCurrentState(object: Instance): string
	if object:GetAttribute("BeingDragged") then return "BeingDragged" end
	if object:GetAttribute("SnappedToGrid") then return "SnappedToGrid" end
	if object:GetAttribute("Interacting") then return "Interacting" end
	if object:GetAttribute("InUse") then return "InUse" end
	if object:GetAttribute("Equipped") then return "Equipped" end
	return "Idle"
end

-- Check if transition is valid
local function CanTransition(fromState: string, toState: string): boolean
	if fromState == toState then return true end

	local validTransitions = VALID_TRANSITIONS[fromState]
	if not validTransitions then return false end

	return table.find(validTransitions, toState) ~= nil
end

-- Clear all state attributes
local function ClearAllStates(object: Instance)
	object:SetAttribute("BeingDragged", nil)
	object:SetAttribute("DraggedBy", nil)
	object:SetAttribute("SnappedToGrid", nil)
	object:SetAttribute("Interacting", nil)
	object:SetAttribute("InUse", nil)
	object:SetAttribute("AttachedTo", nil)
	object:SetAttribute("BrewingPlayer", nil)
	object:SetAttribute("Equipped", nil)
end

-- Set object to a specific state
function ObjectStateManager.SetState(object: Instance, newState: string, stateData: {[string]: any}?): boolean
	local currentState = GetCurrentState(object)

	-- Validate transition
	if not CanTransition(currentState, newState) then
		warn(string.format(
			"[ObjectStateManager] Invalid state transition: %s -> %s for %s",
			currentState,
			newState,
			object:GetFullName()
			))
		return false
	end

	-- Clear old state
	ClearAllStates(object)

	-- Set new state
	if newState == "BeingDragged" then
		object:SetAttribute("BeingDragged", true)
		if stateData and stateData.DraggedBy then
			object:SetAttribute("DraggedBy", stateData.DraggedBy)
		end
	elseif newState == "SnappedToGrid" then
		object:SetAttribute("SnappedToGrid", true)
	elseif newState == "Interacting" then
		object:SetAttribute("Interacting", true)
		if stateData and stateData.Player then
			object:SetAttribute("BrewingPlayer", stateData.Player)
		end
	elseif newState == "InUse" then
		object:SetAttribute("InUse", true)
		if stateData and stateData.AttachedTo then
			object:SetAttribute("AttachedTo", stateData.AttachedTo)
		end
	elseif newState == "Equipped" then
		object:SetAttribute("Equipped", true)
	end

	-- Trigger callbacks
	local callbacks = StateChangeCallbacks[object]
	if callbacks then
		for _, callback in ipairs(callbacks) do
			task.spawn(callback, currentState, newState)
		end
	end

	return true
end

-- Get current state
function ObjectStateManager.GetState(object: Instance): string
	return GetCurrentState(object)
end

-- Check if state transition is allowed
function ObjectStateManager.CanTransition(object: Instance, toState: string): boolean
	local currentState = GetCurrentState(object)
	return CanTransition(currentState, toState)
end

-- Register callback for state changes
function ObjectStateManager.OnStateChanged(object: Instance, callback: (string, string) -> ()): () -> ()
	if not StateChangeCallbacks[object] then
		StateChangeCallbacks[object] = {}
	end

	table.insert(StateChangeCallbacks[object], callback)

	-- Return cleanup function
	return function()
		local callbacks = StateChangeCallbacks[object]
		if callbacks then
			local index = table.find(callbacks, callback)
			if index then
				table.remove(callbacks, index)
			end
		end
	end
end

-- Cleanup callbacks when object is destroyed
function ObjectStateManager.Cleanup(object: Instance): ()
	StateChangeCallbacks[object] = nil
end

-- Force clear all states (emergency use only)
function ObjectStateManager.ForceIdle(object: Instance): ()
	ClearAllStates(object)
end

return ObjectStateManager