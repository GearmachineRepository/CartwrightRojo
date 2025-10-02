--!strict
--!optimize 2
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

-- Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlatformManager = require(Modules:WaitForChild("PlatformManager"))
local KeybindConfig = require(Modules:WaitForChild("KeybindConfig"))
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))
local GlobalNumbers = require(Modules:WaitForChild("GlobalNumbers"))
local ObjectValidator = require(Modules:WaitForChild("ObjectValidator"))

-- Constants
local INTERACTION_TAG: string = "Interactable"
local INTERACTION_DISTANCE: number = GlobalNumbers.SNAP_DISTANCE
local LOOP_RATE = 1/30

-- Services and Objects
local Player: Player = Players.LocalPlayer
local Camera: Camera = workspace.CurrentCamera

-- Remote Events
local Events: Folder = ReplicatedStorage:WaitForChild("Events")

local InteractionEvents: Folder = Events:WaitForChild("InteractionEvents") :: Folder
local InteractRemote: RemoteEvent = InteractionEvents:WaitForChild("Interact") :: RemoteEvent
local DropRemote: RemoteEvent = InteractionEvents:WaitForChild("Drop") :: RemoteEvent

-- Variables
local NearestInteractable: Instance? = nil
local PromptLabel: TextLabel? = nil
local UpdateConnection: RBXScriptConnection?
local CurrentPlatform: string = "PC"
local CurrentBillboard: BillboardGui? = nil
local LongPressTime: number = 0.45
local TouchStartTime: number = 0
local PendingInteractable: Instance? = nil

-- Create a billboard
local function CreateBillboardUI(): BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "InteractionPrompt"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.LightInfluence = 0
	billboard.Enabled = false
	billboard.AlwaysOnTop = true

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.BackgroundTransparency = 1
	frame.BackgroundColor3 = Color3.new(0, 0, 0)
	frame.BorderSizePixel = 0
	frame.Parent = billboard

	local label = Instance.new("TextLabel")
	label.Name = "PromptLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = ""
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansItalic
	label.Parent = frame

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Thickness = 2
	UIStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	UIStroke.Enabled = true
	UIStroke.Parent = label

	return billboard
end

-- Get position for interaction checks
local function GetInteractionPosition(): Vector3
	if not Player.Character then 
		return Vector3.new(0, 0, 0) 
	end

	local Head: BasePart? = Player.Character:FindFirstChild("Head") :: BasePart
	return Head and Head.Position or Player.Character:GetPivot().Position
end

local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude

-- Check if object is in line of sight
local function IsInLineOfSight(object: Instance): boolean
	local PlayerPosition = GetInteractionPosition()

	local filterList: {any} = {}
	if Player.Character then
		table.insert(filterList, Player.Character)
	end
	raycastParams.FilterDescendantsInstances = filterList

	local function CanSeePosition(targetPosition: Vector3): boolean
		local direction = (targetPosition - PlayerPosition).Unit
		local distance = (targetPosition - PlayerPosition).Magnitude

		local raycastResult = workspace:Raycast(PlayerPosition, direction * distance, raycastParams)

		if not raycastResult then
			return true
		end

		local hitInstance = raycastResult.Instance
		if object:IsA("Model") and (hitInstance == object or hitInstance:IsDescendantOf(object)) then
			return true
		elseif object:IsA("BasePart") and hitInstance == object then
			return true
		end

		return false
	end

	if object:IsA("Model") then
		local testPositions = {}

		table.insert(testPositions, object:GetPivot().Position)

		for _, child in pairs(object:GetChildren()) do
			if child:IsA("BasePart") then
				table.insert(testPositions, child.Position)

				local size = child.Size
				local cf = child.CFrame

				local offsets = {
					Vector3.new(size.X/2, 0, 0),
					Vector3.new(-size.X/2, 0, 0),
					Vector3.new(0, size.Y/2, 0),
					Vector3.new(0, -size.Y/2, 0),
					Vector3.new(0, 0, size.Z/2),
					Vector3.new(0, 0, -size.Z/2)
				}

				for _, offset in pairs(offsets) do
					local worldOffset = cf:VectorToWorldSpace(offset)
					table.insert(testPositions, cf.Position + worldOffset)
				end
			end
		end

		for _, position in pairs(testPositions) do
			if CanSeePosition(position) then
				return true
			end
		end

		return false
	elseif object:IsA("BasePart") then
		return CanSeePosition(object.Position)
	end

	return false
end

-- Check if object should show interaction
local function ShouldShowInteraction(object: Instance): boolean
	-- Use validator for state checks
	local promptValidation = ObjectValidator.ShouldShowPrompt(Player, object)

	-- Special handling for wheels - never show prompt if not owned
	if object:GetAttribute("PartType") == "Wheel" then
		if not promptValidation.IsValid then
			return false
		end
	end

	-- For other objects, show ownership info even if not owned
	if not promptValidation.IsValid and not promptValidation.OwnerName then
		return false
	end

	if Player:GetAttribute("Carting") then
		if object:GetAttribute("Type") ~= "Cart" then
			return false
		end

		local owner = object:GetAttribute("Owner")
		if owner == nil or owner ~= Player.UserId then
			return false
		end
	end

	-- Check if cart has minimum wheels requirement
	if object:IsA("Model") and object:HasTag("Cart") then
		local prerequisiteCheck = ObjectValidator.MeetsPrerequisites(object, "pull_cart")
		if not prerequisiteCheck.IsValid then
			return false
		end
	end

	if not IsInLineOfSight(object) then
		return false
	end

	return true
end

-- Get interaction distance for a specific object
local function GetInteractionDistance(object: Instance): number
	local objectConfig = ObjectDatabase.GetObjectConfig(object.Name)
	if objectConfig and objectConfig.InteractionDistance then
		return objectConfig.InteractionDistance
	end

	local attributeDistance = object:GetAttribute("InteractionDistance")
	if attributeDistance and type(attributeDistance) == "number" then
		return attributeDistance
	end

	return INTERACTION_DISTANCE
end

-- Get interaction text for object
local function GetInteractionText(object: Instance): string?
	-- Check if player can interact
	local validation = ObjectValidator.GetValidationInfo(Player, object, "interact")

	-- Show ownership for non-owned objects
	if not validation.IsValid and validation.OwnerName then
		return string.format("Owned by %s", validation.OwnerName)
	end

	-- Show state reasons
	if not validation.IsValid and validation.Reason then
		return validation.Reason
	end

	local objectConfig = ObjectDatabase.GetObjectConfig(object.Name)
	if not objectConfig then
		local fallbackText = object:GetAttribute("InteractionText")
		if fallbackText then
			local platform = CurrentPlatform or "PC"
			return ObjectDatabase.FormatInteractionText(fallbackText, platform)
		end
		return nil
	end

	local currentState = object:GetAttribute("CurrentState") or "StateA"
	local stateConfig = objectConfig[currentState]

	if not stateConfig or not stateConfig.Text then
		return nil
	end

	local platform = CurrentPlatform or "PC"
	return ObjectDatabase.FormatInteractionText(stateConfig.Text, platform)
end

-- Find nearest interactable object
local function FindNearestInteractable(): Instance?
	local PlayerPosition = GetInteractionPosition()
	local ClosestDistance = INTERACTION_DISTANCE
	local ClosestObject: Instance? = nil

	for _, object in pairs(CollectionService:GetTagged(INTERACTION_TAG)) do
		if not ShouldShowInteraction(object) then
			continue
		end

		local InteractionText = GetInteractionText(object)
		if not InteractionText then
			continue
		end

		local ObjectPosition: Vector3
		if object:IsA("Model") then
			ObjectPosition = object:GetPivot().Position
		elseif object:IsA("BasePart") then
			ObjectPosition = object.Position
		else
			continue
		end

		local Distance = (PlayerPosition - ObjectPosition).Magnitude
		local ObjectInteractionDistance = GetInteractionDistance(object)

		if Distance < ClosestDistance then
			if Distance <= ObjectInteractionDistance then
				ClosestDistance = Distance
				ClosestObject = object
			end
		end
	end

	return ClosestObject
end

-- Update interaction prompt
local LastRate = tick()
local function UpdateInteractionPrompt(): ()
	if tick() - LastRate >= LOOP_RATE then
		LastRate = tick()
	end

	local NewNearest = FindNearestInteractable()

	if NewNearest ~= NearestInteractable then
		NearestInteractable = NewNearest

		if NearestInteractable then
			if not CurrentBillboard then
				CurrentBillboard = CreateBillboardUI()
			end

			if not CurrentBillboard then return end

			local BillboardFrame = CurrentBillboard:FindFirstChild("Frame")
			if not BillboardFrame then return end
			PromptLabel = BillboardFrame:FindFirstChild("PromptLabel") :: TextLabel
			if not PromptLabel then return end

			CurrentBillboard.Parent = NearestInteractable
			local InteractionText = GetInteractionText(NearestInteractable)
			if InteractionText then
				PromptLabel.Text = InteractionText
				CurrentBillboard.Enabled = true
			else
				CurrentBillboard.Enabled = false
			end
		else
			if CurrentBillboard then
				CurrentBillboard.Enabled = false
			end
		end
	elseif NearestInteractable and CurrentBillboard and CurrentBillboard.Enabled then
		local InteractionText = GetInteractionText(NearestInteractable)

		local BillboardFrame = CurrentBillboard:FindFirstChild("Frame")
		if not BillboardFrame then return end
		PromptLabel = BillboardFrame:FindFirstChild("PromptLabel") :: TextLabel
		if not PromptLabel then return end

		if InteractionText and PromptLabel.Text ~= InteractionText then
			PromptLabel.Text = InteractionText
		elseif not InteractionText then
			CurrentBillboard.Enabled = false
		end
	end
end

-- Handle interaction input (InputBegan)
local function OnInteractionInput(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then return end

	local InteractKeybind = KeybindConfig.GetKeybind(CurrentPlatform, "Interact")
	local DropKeybind = KeybindConfig.GetKeybind(CurrentPlatform, "Drop")

	local IsInteractInput = false
	if CurrentPlatform == "Mobile" then
		if input.UserInputType == Enum.UserInputType.Touch and input.UserInputState == Enum.UserInputState.Begin then
			local touchPosition = input.Position
			local touchedUI = false

			local success, guiObjects = pcall(function()
				return game.Players.LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(touchPosition.X, touchPosition.Y)
			end)

			if success and guiObjects then
				for _, guiObject in ipairs(guiObjects) do
					local objName = guiObject.Name:lower()

					if objName:find("thumbstick") or 
						objName:find("dynamicthumbstick") or
						objName:find("joystick") or
						objName:find("movepad") or
						objName:find("dpad") then
						touchedUI = true
						break
					end
				end
			end

			if not touchedUI then
				TouchStartTime = tick()
				PendingInteractable = NearestInteractable
			end
		end
	else
		IsInteractInput = input.KeyCode == InteractKeybind or input.UserInputType == InteractKeybind

		if IsInteractInput and NearestInteractable then
			SoundService["Sound Effects"].Interact.PlaybackSpeed = 1 * (math.random()/10)
			SoundService["Sound Effects"].Interact:Play()
			InteractRemote:FireServer(NearestInteractable)
		end
	end

	if CurrentPlatform == "Controller" then
		if DropKeybind and input.KeyCode == DropKeybind then
			DropRemote:FireServer()
		end
	end
end

-- Handle input ended (separate function for InputEnded)
local function OnInteractionInputEnded(input: InputObject, gameProcessed: boolean): ()
	if gameProcessed then return end

	if CurrentPlatform == "Mobile" and input.UserInputType == Enum.UserInputType.Touch then
		local currentTime = tick()
		local holdDuration = currentTime - TouchStartTime

		if holdDuration >= LongPressTime then
			local character = game.Players.LocalPlayer.Character
			local holdingTool = character and character:FindFirstChildWhichIsA("Tool")

			if holdingTool then
				DropRemote:FireServer()
			elseif PendingInteractable then
				SoundService["Sound Effects"].Interact.PlaybackSpeed = 1 * (math.random()/10)
				SoundService["Sound Effects"].Interact:Play()
				InteractRemote:FireServer(PendingInteractable)
			end
		else
			if PendingInteractable then
				SoundService["Sound Effects"].Interact.PlaybackSpeed = 1 * (math.random()/10)
				SoundService["Sound Effects"].Interact:Play()
				InteractRemote:FireServer(PendingInteractable)
			end
		end
		PendingInteractable = nil
	end
end

-- Handle platform switching
local function OnPlatformChanged(newPlatform: string): ()
	CurrentPlatform = newPlatform

	if NearestInteractable and CurrentBillboard and CurrentBillboard.Enabled then
		local InteractionText = GetInteractionText(NearestInteractable)
		if InteractionText then
			if CurrentBillboard then
				local BillboardFrame = CurrentBillboard:FindFirstChild("Frame")
				if not BillboardFrame then return end
				PromptLabel = BillboardFrame:FindFirstChild("PromptLabel") :: TextLabel
				if not PromptLabel then return end
				PromptLabel.Text = InteractionText
			end
		end
	end
end

-- Initialize
local function Initialize(): ()
	CurrentPlatform = PlatformManager.GetPlatform() or "PC"

	CreateBillboardUI()
	PlatformManager.OnPlatformChanged(OnPlatformChanged)
	UpdateConnection = RunService.Heartbeat:Connect(UpdateInteractionPrompt)
	UserInputService.InputBegan:Connect(OnInteractionInput)
	UserInputService.InputEnded:Connect(OnInteractionInputEnded)
end

-- Cleanup
local function Cleanup(): ()
	if UpdateConnection then
		UpdateConnection:Disconnect()
		UpdateConnection = nil
	end

	if CurrentBillboard then
		CurrentBillboard:Destroy()
		CurrentBillboard = nil
		PromptLabel = nil
	end

	NearestInteractable = nil
end

-- Character events
Player.CharacterAdded:Connect(function()
	task.wait(1)
	Initialize()
end)

Player.CharacterRemoving:Connect(Cleanup)

if Player.Character then
	Initialize()
end