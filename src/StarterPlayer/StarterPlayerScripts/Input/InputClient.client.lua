--!strict
--!optimize 2
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlatformManager = require(Modules:WaitForChild("PlatformManager"))
local KeybindConfig = require(Modules:WaitForChild("KeybindConfig"))
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))
local ObjectValidator = require(Modules:WaitForChild("ObjectValidator"))
local Maid = require(Modules:WaitForChild("Maid"))

local INTERACTION_TAG: string = "Interactable"
local INTERACTION_DISTANCE: number = GeneralUtil.SNAP_DISTANCE
local LOOP_RATE = 1/30

local Player: Player = Players.LocalPlayer

local Events: Folder = ReplicatedStorage:WaitForChild("Events")
local InteractionEvents: Folder = Events:WaitForChild("InteractionEvents") :: Folder
local InteractRemote: RemoteEvent = InteractionEvents:WaitForChild("Interact") :: RemoteEvent
local DropRemote: RemoteEvent = InteractionEvents:WaitForChild("Drop") :: RemoteEvent

type MaidType = typeof(Maid.new())

local CharacterMaid: MaidType = Maid.new()
local NearestInteractable: Instance? = nil
local PromptLabel: TextLabel? = nil
local CurrentPlatform: string = "PC"
local CurrentBillboard: BillboardGui? = nil
local LongPressTime: number = 0.45
local TouchStartTime: number = 0
local PendingInteractable: Instance? = nil

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local function CreateBillboardUI(): BillboardGui
	local Billboard = Instance.new("BillboardGui")
	Billboard.Name = "InteractionPrompt"
	Billboard.Size = UDim2.fromOffset(200, 50)
	Billboard.StudsOffset = Vector3.new(0, 3, 0)
	Billboard.LightInfluence = 0
	Billboard.Enabled = false
	Billboard.AlwaysOnTop = true

	local Frame = Instance.new("Frame")
	Frame.Size = UDim2.fromScale(1, 1)
	Frame.BackgroundTransparency = 1
	Frame.BackgroundColor3 = Color3.new(0, 0, 0)
	Frame.BorderSizePixel = 0
	Frame.Parent = Billboard

	local Label = Instance.new("TextLabel")
	Label.Name = "PromptLabel"
	Label.Size = UDim2.fromScale(1, 1)
	Label.BackgroundTransparency = 1
	Label.Text = ""
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextScaled = true
	Label.Font = Enum.Font.SourceSansItalic
	Label.Parent = Frame

	local UIStroke = Instance.new("UIStroke")
	UIStroke.Thickness = 2
	UIStroke.BorderStrokePosition = Enum.BorderStrokePosition.Outer
	UIStroke.Enabled = true
	UIStroke.Parent = Label

	return Billboard
end

local function GetInteractionPosition(): Vector3
	if not Player.Character then 
		return Vector3.new(0, 0, 0) 
	end

	local Head: BasePart? = Player.Character:FindFirstChild("Head") :: BasePart
	return Head and Head.Position or Player.Character:GetPivot().Position
end

local function IsInLineOfSight(Object: Instance): boolean
	local PlayerPosition = GetInteractionPosition()

	local FilterList: {any} = {}
	if Player.Character then
		table.insert(FilterList, Player.Character)
	end
	RaycastParams.FilterDescendantsInstances = FilterList

	local function CanSeePosition(TargetPosition: Vector3): boolean
		local Direction = (TargetPosition - PlayerPosition).Unit
		local Distance = (TargetPosition - PlayerPosition).Magnitude

		local RaycastResult = workspace:Raycast(PlayerPosition, Direction * Distance, RaycastParams)

		if not RaycastResult then
			return true
		end

		local HitInstance = RaycastResult.Instance
		if Object:IsA("Model") and (HitInstance == Object or HitInstance:IsDescendantOf(Object)) then
			return true
		elseif Object:IsA("BasePart") and HitInstance == Object then
			return true
		end

		return false
	end

	if Object:IsA("Model") then
		local TestPositions = {}

		table.insert(TestPositions, Object:GetPivot().Position)

		for _, Child in pairs(Object:GetChildren()) do
			if Child:IsA("BasePart") then
				table.insert(TestPositions, Child.Position)

				local Size = Child.Size
				local Cf = Child.CFrame

				local Offsets = {
					Vector3.new(Size.X/2, 0, 0),
					Vector3.new(-Size.X/2, 0, 0),
					Vector3.new(0, Size.Y/2, 0),
					Vector3.new(0, -Size.Y/2, 0),
					Vector3.new(0, 0, Size.Z/2),
					Vector3.new(0, 0, -Size.Z/2)
				}

				for _, Offset in pairs(Offsets) do
					local WorldOffset = Cf:VectorToWorldSpace(Offset)
					table.insert(TestPositions, Cf.Position + WorldOffset)
				end
			end
		end

		for _, Position in pairs(TestPositions) do
			if CanSeePosition(Position) then
				return true
			end
		end

		return false
	elseif Object:IsA("BasePart") then
		return CanSeePosition(Object.Position)
	end

	return false
end

local function ShouldShowInteraction(Object: Instance): boolean
	local PromptValidation = ObjectValidator.ShouldShowPrompt(Player, Object)

	if Object:GetAttribute("PartType") == "Wheel" then
		if not PromptValidation.IsValid then
			return false
		end
	end

	if not PromptValidation.IsValid and not PromptValidation.OwnerName then
		return false
	end

	if Player:GetAttribute("Carting") then
		if Object:GetAttribute("Type") ~= "Cart" then
			return false
		end

		local Owner = Object:GetAttribute("Owner")
		if Owner == nil or Owner ~= Player.UserId then
			return false
		end
	end

	if Object:IsA("Model") and Object:HasTag("Cart") then
		local PrerequisiteCheck = ObjectValidator.MeetsPrerequisites(Object, "pull_cart")
		if not PrerequisiteCheck.IsValid then
			return false
		end
	end

	if not IsInLineOfSight(Object) then
		return false
	end

	return true
end

local function GetInteractionDistance(Object: Instance): number
	local ObjectConfig = ObjectDatabase.GetObjectConfig(Object.Name)
	if ObjectConfig and ObjectConfig.InteractionDistance then
		return ObjectConfig.InteractionDistance
	end

	local AttributeDistance = Object:GetAttribute("InteractionDistance")
	if AttributeDistance and type(AttributeDistance) == "number" then
		return AttributeDistance
	end

	return INTERACTION_DISTANCE
end

local function GetInteractionText(Object: Instance): string?
	local Validation = ObjectValidator.GetValidationInfo(Player, Object, "interact")

	if not Validation.IsValid and Validation.OwnerName then
		return string.format("Owned by %s", Validation.OwnerName)
	end

	if not Validation.IsValid and Validation.Reason then
		return Validation.Reason
	end

	local ObjectConfig = ObjectDatabase.GetObjectConfig(Object.Name)
	if not ObjectConfig then
		local FallbackText = Object:GetAttribute("InteractionText")
		if FallbackText then
			local Platform = CurrentPlatform or "PC"
			return ObjectDatabase.FormatInteractionText(FallbackText, Platform)
		end
		return nil
	end

	local CurrentState = Object:GetAttribute("CurrentState") or "StateA"
	local StateConfig = ObjectConfig[CurrentState]

	if not StateConfig or not StateConfig.Text then
		return nil
	end

	local Platform = CurrentPlatform or "PC"
	return ObjectDatabase.FormatInteractionText(StateConfig.Text, Platform)
end

local function FindNearestInteractable(): Instance?
	local PlayerPosition = GetInteractionPosition()
	local ClosestDistance = INTERACTION_DISTANCE
	local ClosestObject: Instance? = nil

	for _, Object in pairs(CollectionService:GetTagged(INTERACTION_TAG)) do
		if not ShouldShowInteraction(Object) then
			continue
		end

		local InteractionText = GetInteractionText(Object)
		if not InteractionText then
			continue
		end

		local ObjectPosition: Vector3
		if Object:IsA("Model") then
			ObjectPosition = Object:GetPivot().Position
		elseif Object:IsA("BasePart") then
			ObjectPosition = Object.Position
		else
			continue
		end

		local Distance = (PlayerPosition - ObjectPosition).Magnitude
		local ObjectInteractionDistance = GetInteractionDistance(Object)

		if Distance < ClosestDistance then
			if Distance <= ObjectInteractionDistance then
				ClosestDistance = Distance
				ClosestObject = Object
			end
		end
	end

	return ClosestObject
end

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

local function OnInteractionInput(Input: InputObject, GameProcessed: boolean): ()
	if GameProcessed then return end

	local InteractKeybind = KeybindConfig.GetKeybind(CurrentPlatform, "Interact")
	local DropKeybind = KeybindConfig.GetKeybind(CurrentPlatform, "Drop")

	local IsInteractInput = false
	if CurrentPlatform == "Mobile" then
		if Input.UserInputType == Enum.UserInputType.Touch and Input.UserInputState == Enum.UserInputState.Begin then
			local TouchPosition = Input.Position
			local TouchedUI = false

			local Success, GuiObjects = pcall(function()
				return Player.PlayerGui:GetGuiObjectsAtPosition(TouchPosition.X, TouchPosition.Y)
			end)

			if Success and GuiObjects then
				for _, GuiObject in ipairs(GuiObjects) do
					local ObjName = GuiObject.Name:lower()

					if ObjName:find("thumbstick") or
						ObjName:find("joystick") or
						ObjName:find("movepad") or
						ObjName:find("dpad") then
						TouchedUI = true
						break
					end
				end
			end

			if not TouchedUI then
				TouchStartTime = tick()
				PendingInteractable = NearestInteractable
			end
		end
	else
		IsInteractInput = Input.KeyCode == InteractKeybind or Input.UserInputType == InteractKeybind

		if IsInteractInput and NearestInteractable then
			SoundService["Sound Effects"].Interact.PlaybackSpeed = 1 * (math.random()/10)
			SoundService["Sound Effects"].Interact:Play()
			InteractRemote:FireServer(NearestInteractable)
		end
	end

	if CurrentPlatform == "Controller" then
		if DropKeybind and Input.KeyCode == DropKeybind then
			DropRemote:FireServer()
		end
	end
end

local function OnInteractionInputEnded(Input: InputObject, GameProcessed: boolean): ()
	if GameProcessed then return end

	if CurrentPlatform == "Mobile" and Input.UserInputType == Enum.UserInputType.Touch then
		local CurrentTime = tick()
		local HoldDuration = CurrentTime - TouchStartTime

		if HoldDuration >= LongPressTime then
			local Character = Player.Character
			local HoldingTool = Character and Character:FindFirstChildWhichIsA("Tool")

			if HoldingTool then
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

local function OnPlatformChanged(NewPlatform: string): ()
	CurrentPlatform = NewPlatform

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

local function Initialize(): ()
	CurrentPlatform = PlatformManager.GetPlatform() or "PC"

	CreateBillboardUI()
	
	local DisconnectPlatform = PlatformManager.OnPlatformChanged(OnPlatformChanged)
	if DisconnectPlatform then
		CharacterMaid:GiveTask(DisconnectPlatform)
	end
	
	CharacterMaid:GiveTask(RunService.Heartbeat:Connect(UpdateInteractionPrompt))
	CharacterMaid:GiveTask(UserInputService.InputBegan:Connect(OnInteractionInput))
	CharacterMaid:GiveTask(UserInputService.InputEnded:Connect(OnInteractionInputEnded))
end

local function Cleanup(): ()
	CharacterMaid:DoCleaning()

	if CurrentBillboard then
		CurrentBillboard:Destroy()
		CurrentBillboard = nil
		PromptLabel = nil
	end

	NearestInteractable = nil
end

CharacterMaid:GiveTask(Player.CharacterAdded:Connect(function()
	task.wait(1)
	Initialize()
end))

CharacterMaid:GiveTask(Player.CharacterRemoving:Connect(Cleanup))

if Player.Character then
	Initialize()
end