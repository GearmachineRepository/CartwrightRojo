--!strict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local DialogModules = ReplicatedStorage:WaitForChild("Modules")
local DialogText = require(DialogModules:WaitForChild("DialogText"))
local State = require(DialogModules:WaitForChild("State"))
local DialogHandler = require(DialogModules:WaitForChild("DialogHandler"))
local Visuals = require(DialogModules:WaitForChild("Visuals"))

local Events = ReplicatedStorage:WaitForChild("Events")
local DialogEvents = Events:WaitForChild("DialogEvents")
local StartDialogRemote = DialogEvents:WaitForChild("StartDialog") :: RemoteEvent
local StopDialogRemote = DialogEvents:WaitForChild("StopDialog") :: RemoteEvent

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local USE_BLUR = false
local MAX_DISTANCE = 17

local ActiveNpcModel: Model? = nil
local IsInDialog = false
local CancelRequested = false
local CurrentHighlight: Highlight? = nil

local function CancelDialog(): ()
	CancelRequested = true
	IsInDialog = false

	Visuals.Change_FOV(Visuals.Return_Core_FOV())

	if CurrentHighlight then
		TweenService:Create(CurrentHighlight, TWEEN_INFO, {OutlineTransparency = 1}):Play()
		Debris:AddItem(CurrentHighlight, TWEEN_INFO.Time)
		CurrentHighlight = nil
	end

	if ActiveNpcModel then
		DialogText.TakeAwayResponses(ActiveNpcModel, LocalPlayer)
		StopDialogRemote:FireServer(ActiveNpcModel)
	end

	State.End_Speak(LocalPlayer)
	ActiveNpcModel = nil
end

local function StartDialog(NpcModel: Model): ()
	if not State.Can_Speak(LocalPlayer) then return end
	if IsInDialog then return end

	IsInDialog = true
	CancelRequested = false
	ActiveNpcModel = NpcModel

	State.Start_Speak(LocalPlayer, USE_BLUR)

	CurrentHighlight = Instance.new("Highlight")
	CurrentHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	CurrentHighlight.FillTransparency = 1
	CurrentHighlight.OutlineTransparency = 1
	CurrentHighlight.Adornee = NpcModel
	CurrentHighlight.Parent = NpcModel
	TweenService:Create(CurrentHighlight, TWEEN_INFO, {OutlineTransparency = 0}):Play()

	DialogHandler.Start(NpcModel, LocalPlayer, function()
		CancelDialog()
	end)
end

StartDialogRemote.OnClientEvent:Connect(function(NpcModel: Model)
	if NpcModel and NpcModel:IsA("Model") then
		StartDialog(NpcModel)
	end
end)

local NpcStartPosition: Vector3 = Vector3.zero

task.spawn(function()
	while true do
		task.wait(0.1)
		if IsInDialog and ActiveNpcModel and LocalPlayer.Character and LocalPlayer.Character.PrimaryPart then
			if ActiveNpcModel.PrimaryPart then
				NpcStartPosition = ActiveNpcModel.PrimaryPart.Position
			end

			local Distance = (LocalPlayer.Character.PrimaryPart.Position - NpcStartPosition).Magnitude
			if Distance > MAX_DISTANCE then
				DialogText.NpcText(ActiveNpcModel, "Farewell...", true)
				CancelDialog()
			end
		end
	end
end)

print("[DialogClient] Client initialized")