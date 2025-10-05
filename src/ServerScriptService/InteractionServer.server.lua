--!strict
--!optimize 2
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))
local ObjectValidator = require(Modules:WaitForChild("ObjectValidator"))
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))

local ServerModules = script.Parent:WaitForChild("ServerModules")
local InteractionFunctions = require(ServerModules:WaitForChild("InteractionFunctions"))

local INTERACTION_TAG: string = "Interactable"

local Events: Folder = ReplicatedStorage:WaitForChild("Events") :: Folder
local InteractionEvents: Folder = Events:WaitForChild("InteractionEvents") :: Folder
local InteractRemote: RemoteEvent = InteractionEvents:WaitForChild("Interact") :: RemoteEvent

local function IsValidInteraction(Player: Player, Object: Instance): boolean
	if not CollectionService:HasTag(Object, INTERACTION_TAG) then
		return false
	end

	local Validation = ObjectValidator.CanInteract(Player, Object)
	if not Validation.IsValid then
		return false
	end

	if Player:GetAttribute("Carting") and Object:GetAttribute("Type") ~= "Cart" then
		return false
	end

	if Object:IsA("Model") and Object:HasTag("Cart") then
		local WheelCount = 0
		for _, Descendant in ipairs(Object:GetDescendants()) do
			if Descendant:IsA("Model") and Descendant:GetAttribute("PartType") == "Wheel" then
				WheelCount += 1
			end
		end

		if WheelCount < 2 then
			return false
		end
	end

	local Character = Player.Character
	if not Character then return false end

	local PlayerPosition = Character:GetPivot().Position
	local ObjectPosition: Vector3

	if Object:IsA("Model") then
		ObjectPosition = Object:GetPivot().Position
	elseif Object:IsA("BasePart") then
		ObjectPosition = Object.Position
	else
		return false
	end

	local Distance = GeneralUtil.Distance(PlayerPosition, ObjectPosition)
	if Distance > GeneralUtil.INTERACTION_DISTANCE then
		return false
	end

	return true
end

local function OnInteract(Player: Player, Object: Instance): ()
	if not IsValidInteraction(Player, Object) then
		return
	end

	local ObjectConfig = ObjectDatabase.GetObjectConfig(Object.Name)
	if not ObjectConfig then
		warn("No config found for object:", Object.Name)
		return
	end

	local CurrentState = Object:GetAttribute("CurrentState") or "StateA"

	if ObjectConfig.Type == "NPC" then
		CurrentState = "StateA"
	end

	local StateConfig = ObjectConfig[CurrentState]

	if not StateConfig or not StateConfig.Function then
		warn("No function defined for", Object.Name, "state:", CurrentState)
		return
	end

	InteractionFunctions.ExecuteInteraction(
		Player,
		Object,
		ObjectConfig.Type,
		StateConfig.Function,
		ObjectConfig
	)
end

InteractRemote.OnServerEvent:Connect(OnInteract)