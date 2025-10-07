--!strict
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local DialogModules = ReplicatedStorage:WaitForChild("Modules")
local DialogText = require(DialogModules:WaitForChild("DialogText"))
local State = require(DialogModules:WaitForChild("State"))
local Visuals = require(DialogModules:WaitForChild("Visuals"))

local Events = ReplicatedStorage:WaitForChild("Events")
local DialogEvents = Events:WaitForChild("DialogEvents")
local StartDialogRemote = DialogEvents:WaitForChild("StartDialog") :: RemoteEvent
local StopDialogRemote = DialogEvents:WaitForChild("StopDialog") :: RemoteEvent
local ShowDialogRemote = DialogEvents:WaitForChild("ShowDialog") :: RemoteEvent
local DialogChoiceRemote = DialogEvents:WaitForChild("DialogChoice") :: RemoteEvent
local PlaySkillCheckSoundRemote = DialogEvents:WaitForChild("PlaySkillCheckSound") :: RemoteEvent

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local USE_BLUR = false
local MAX_DISTANCE = 17

local ActiveNpcModel: Model? = nil
local IsInDialog = false
local CurrentHighlight: Highlight? = nil
local NpcStartPosition: Vector3 = Vector3.zero
--local CurrentButtons: {Instance} = {}
local CurrentConnections: {RBXScriptConnection} = {}

local function CleanupDialog(): ()
	for _, Connection in ipairs(CurrentConnections) do
		Connection:Disconnect()
	end
	CurrentConnections = {}
	--CurrentButtons = {}
end

local function CancelDialog(): ()
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
	CleanupDialog()
end

local function StartDialog(NpcModel: Model): ()
	if not State.Can_Speak(LocalPlayer) then return end
	if IsInDialog then return end

	IsInDialog = true
	ActiveNpcModel = NpcModel

	State.Start_Speak(LocalPlayer, USE_BLUR)

	CurrentHighlight = Instance.new("Highlight")
	CurrentHighlight.DepthMode = Enum.HighlightDepthMode.Occluded
	CurrentHighlight.FillTransparency = 1
	CurrentHighlight.OutlineTransparency = 1
	CurrentHighlight.Adornee = NpcModel
	CurrentHighlight.Parent = NpcModel
	TweenService:Create(CurrentHighlight, TWEEN_INFO, {OutlineTransparency = 0}):Play()
end

StartDialogRemote.OnClientEvent:Connect(function(NpcModel: Model)
	if NpcModel and NpcModel:IsA("Model") then
		StartDialog(NpcModel)
	end
end)

PlaySkillCheckSoundRemote.OnClientEvent:Connect(function(SoundName: string)
	local SoundEffects = game:GetService("SoundService"):WaitForChild("Sound Effects")
	local Sound = SoundEffects:FindFirstChild(SoundName)

	if Sound then
		Sound:Play()
	else
		warn("[DialogClient] Skill check sound not found:", SoundName)
	end
end)

ShowDialogRemote.OnClientEvent:Connect(function(NpcModel: Model, Text: string, Choices: {string}?, IsEnd: boolean)
	if not IsInDialog or ActiveNpcModel ~= NpcModel then
		print("[DialogClient] Ignoring - not in dialog or wrong NPC")
		return
	end

	CleanupDialog()

	local _, DialogForcedEnd = DialogText.NpcText(NpcModel, Text, true)

	if DialogForcedEnd then
		CancelDialog()
		return
	end

	if Choices and #Choices > 0 then
		local Buttons = DialogText.ShowChoices(LocalPlayer, Choices)
		--CurrentButtons = Buttons

		for _, Button in pairs(Buttons) do
			local Frame = Button:FindFirstChild("Frame")
			if Frame and Frame:FindFirstChild("ImageButton") then
				local Connection = Frame.ImageButton.MouseButton1Click:Connect(function()
					local ChoiceText = Frame.Frame.Text_Element:GetAttribute("Text")
					if ChoiceText then
						DialogText.RemovePlayerSideFrame(LocalPlayer)
						DialogText.PlayerResponse(LocalPlayer.Character, ChoiceText, true)
						task.wait(0.5)
						DialogChoiceRemote:FireServer(ChoiceText)
					end
				end)
				table.insert(CurrentConnections, Connection)
			end
		end
	elseif IsEnd then
		task.wait(2)
		CancelDialog()
	end
end)


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