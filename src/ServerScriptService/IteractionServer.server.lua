--!strict
--!optimize 2
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))
local ObjectValidator = require(Modules:WaitForChild("ObjectValidator"))

local ServerModules = script.Parent:WaitForChild("ServerModules")
local InteractionFunctions = require(ServerModules:WaitForChild("InteractionFunctions"))

-- Constants
local INTERACTION_TAG: string = "Interactable"
local MAX_INTERACTION_DISTANCE: number = 8

-- Remote Events
local Events: Folder = ReplicatedStorage:WaitForChild("Events") :: Folder
local InteractionEvents: Folder = Events:WaitForChild("InteractionEvents") :: Folder
local InteractRemote: RemoteEvent = InteractionEvents:WaitForChild("Interact") :: RemoteEvent

-- Validation
local function IsValidInteraction(player: Player, object: Instance): boolean
	if not CollectionService:HasTag(object, INTERACTION_TAG) then
		return false
	end

	local validation = ObjectValidator.CanInteract(player, object)
	if not validation.IsValid then
		return false
	end

	if player:GetAttribute("Carting") and object:GetAttribute("Type") ~= "Cart" then
		return false
	end

	if object:IsA("Model") and object:HasTag("Cart") then
		local wheelCount = 0
		for _, descendant in ipairs(object:GetDescendants()) do
			if descendant:IsA("Model") and descendant:GetAttribute("PartType") == "Wheel" then
				wheelCount += 1
			end
		end

		if wheelCount < 2 then
			return false
		end
	end

	-- Check distance
	local character = player.Character
	if not character then return false end

	local playerPosition = character:GetPivot().Position
	local objectPosition: Vector3

	if object:IsA("Model") then
		objectPosition = object:GetPivot().Position
	elseif object:IsA("BasePart") then
		objectPosition = object.Position
	else
		return false
	end

	local distance = (playerPosition - objectPosition).Magnitude
	if distance > MAX_INTERACTION_DISTANCE then
		return false
	end

	return true
end

-- Handle interaction
local function OnInteract(player: Player, object: Instance): ()
	-- Validate interaction
	if not IsValidInteraction(player, object) then
		return
	end

	-- Get object config
	local objectConfig = ObjectDatabase.GetObjectConfig(object.Name)
	if not objectConfig then
		warn("No config found for object:", object.Name)
		return
	end

	-- Get current state and function
	local currentState = object:GetAttribute("CurrentState") or "StateA"
	local stateConfig = objectConfig[currentState]

	if not stateConfig or not stateConfig.Function then
		warn("No function defined for", object.Name, "state:", currentState)
		return
	end

	-- Execute interaction
	InteractionFunctions.ExecuteInteraction(
		player, 
		object, 
		objectConfig.Type, 
		stateConfig.Function, 
		objectConfig
	)
end

-- Connect events
InteractRemote.OnServerEvent:Connect(OnInteract)