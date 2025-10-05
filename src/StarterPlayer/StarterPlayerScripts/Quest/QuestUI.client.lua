--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(Modules:WaitForChild("QuestManager"))

local Events = ReplicatedStorage:WaitForChild("Events")
local QuestEvents = Events:WaitForChild("QuestEvents")
local UpdateQuestRemote = QuestEvents:WaitForChild("UpdateQuest") :: RemoteEvent
local QuestStateChangedRemote = QuestEvents:WaitForChild("QuestStateChanged") :: RemoteEvent

type Quest = QuestManager.Quest
type QuestObjective = QuestManager.QuestObjective

local QuestContainer: Frame
local QuestFrames: {[string]: Frame} = {}
local QuestCompassImages: {[ImageLabel]: {Target: Vector3, QuestId: string}} = {}

local TWEEN_INFO = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local COMPASS_IMAGE = "rbxassetid://138007024966757"

local function FindTargetPosition(ObjectiveType: string, TargetId: string): Vector3?
	if ObjectiveType == "Deliver" or ObjectiveType == "TalkTo" then
		local Target = Workspace:FindFirstChild(TargetId, true)
		if Target and Target:IsA("Model") and Target.PrimaryPart then
			return Target.PrimaryPart.Position
		end
	elseif ObjectiveType == "Interact" then
		local Target = Workspace:FindFirstChild(TargetId, true)
		if Target then
			if Target:IsA("Model") and Target.PrimaryPart then
				return Target.PrimaryPart.Position
			elseif Target:IsA("BasePart") then
				return Target.Position
			end
		end
	end

	return nil
end

local function CreateMiniCompass(Parent: Frame, TargetPosition: Vector3, QuestId: string): ImageLabel
	local CompassImage = Instance.new("ImageLabel")
	CompassImage.Name = "MiniCompass"
	CompassImage.Size = UDim2.fromOffset(16, 16)
	CompassImage.Position = UDim2.fromScale(0, 0.5)
	CompassImage.BackgroundTransparency = 1
	CompassImage.Image = COMPASS_IMAGE
	CompassImage.AnchorPoint = Vector2.new(0, 0.5)
	CompassImage.ImageTransparency = 0
	CompassImage.Parent = Parent

	QuestCompassImages[CompassImage] = {Target = TargetPosition, QuestId = QuestId}

	return CompassImage
end

local function UpdateCompassRotations(): ()
	local Camera = Workspace.CurrentCamera
	if not Camera then return end

	local CameraPosition = Camera.CFrame.Position
	local CameraLookVector = Camera.CFrame.LookVector

	for CompassImage, Data in pairs(QuestCompassImages) do
		if CompassImage.Parent then
			local Direction = (Data.Target - CameraPosition).Unit
			local DotProduct = CameraLookVector.X * Direction.X + CameraLookVector.Z * Direction.Z
			local CrossProduct = CameraLookVector.X * Direction.Z - CameraLookVector.Z * Direction.X
			local Angle = math.atan2(CrossProduct, DotProduct)

			CompassImage.Rotation = math.deg(Angle)
		else
			QuestCompassImages[CompassImage] = nil
		end
	end
end

local function CreateQuestTracker(): ScreenGui
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "QuestTrackerGui"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 50

	local Container = Instance.new("Frame")
	Container.Name = "QuestContainer"
	Container.Position = UDim2.fromOffset(20, 20)
	Container.Size = UDim2.fromOffset(300, 0)
	Container.BackgroundTransparency = 1
	Container.Parent = ScreenGui

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, 10)
	Layout.Parent = Container

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Container.Size = UDim2.fromOffset(300, Layout.AbsoluteContentSize.Y)
	end)

	QuestContainer = Container
	ScreenGui.Parent = PlayerGui

	return ScreenGui
end

local function CreateQuestFrame(Quest: Quest): Frame
	local QuestFrame = Instance.new("Frame")
	QuestFrame.Name = "Quest_" .. Quest.Id
	QuestFrame.Size = UDim2.fromScale(1, 0)
	QuestFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	QuestFrame.BackgroundTransparency = 0.3
	QuestFrame.BorderSizePixel = 0

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = QuestFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingTop = UDim.new(0, 8)
	Padding.PaddingBottom = UDim.new(0, 8)
	Padding.PaddingLeft = UDim.new(0, 10)
	Padding.PaddingRight = UDim.new(0, 10)
	Padding.Parent = QuestFrame

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, 4)
	Layout.Parent = QuestFrame

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		QuestFrame.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 16)
	end)

	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.LayoutOrder = 1
	Title.Size = UDim2.new(1, 0, 0, 20)
	Title.BackgroundTransparency = 1
	Title.TextScaled = true
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = QuestFrame

	if Quest.ReadyToTurnIn then
		Title.Text = "[TURN IN] " .. Quest.Title
		Title.TextColor3 = Color3.fromRGB(100, 255, 255)
	else
		Title.Text = Quest.Title
		Title.TextColor3 = Color3.fromRGB(255, 220, 100)
	end

	for Index, Objective in ipairs(Quest.Objectives) do
		local ObjectiveLabel = Instance.new("TextLabel")
		ObjectiveLabel.Name = "Objective_" .. tostring(Index)
		ObjectiveLabel.LayoutOrder = Index + 1
		ObjectiveLabel.Size = UDim2.new(1, 0, 0, 16)
		ObjectiveLabel.BackgroundTransparency = 1
		ObjectiveLabel.TextScaled = true
		ObjectiveLabel.Font = Enum.Font.Gotham
		ObjectiveLabel.TextXAlignment = Enum.TextXAlignment.Left
		ObjectiveLabel.Parent = QuestFrame

		local ProgressText = string.format("%d/%d", Objective.CurrentAmount, Objective.RequiredAmount)

		if Objective.Completed then
			ObjectiveLabel.Text = "  - " .. Objective.Description .. " (" .. ProgressText .. ")"
			ObjectiveLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
			ObjectiveLabel.TextStrokeTransparency = 0.8
		else
			ObjectiveLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			ObjectiveLabel.TextStrokeTransparency = 0.9

			if Objective.Trackable ~= false and (Objective.Type == "Deliver" or Objective.Type == "TalkTo" or Objective.Type == "Interact") then
				if Objective.TargetId then
					local TargetPos = FindTargetPosition(Objective.Type, Objective.TargetId)
					if TargetPos then
						CreateMiniCompass(ObjectiveLabel, TargetPos, Quest.Id)
						ObjectiveLabel.Text = "      " .. Objective.Description .. " (" .. ProgressText .. ")"
					else
						ObjectiveLabel.Text = "  - " .. Objective.Description .. " (" .. ProgressText .. ")"
					end
				else
					ObjectiveLabel.Text = "  - " .. Objective.Description .. " (" .. ProgressText .. ")"
				end
			else
				ObjectiveLabel.Text = "  - " .. Objective.Description .. " (" .. ProgressText .. ")"
			end
		end
	end

	if Quest.ReadyToTurnIn and Quest.TurnInNpc then
		local TurnInLabel = Instance.new("TextLabel")
		TurnInLabel.Name = "TurnInLabel"
		TurnInLabel.LayoutOrder = #Quest.Objectives + 2
		TurnInLabel.Size = UDim2.new(1, 0, 0, 16)
		TurnInLabel.BackgroundTransparency = 1
		TurnInLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
		TurnInLabel.TextScaled = true
		TurnInLabel.Font = Enum.Font.GothamBold
		TurnInLabel.TextXAlignment = Enum.TextXAlignment.Left
		TurnInLabel.Parent = QuestFrame

		local TargetPos = FindTargetPosition("TalkTo", Quest.TurnInNpc)
		if TargetPos then
			CreateMiniCompass(TurnInLabel, TargetPos, Quest.Id)
			TurnInLabel.Text = "      Return to " .. Quest.TurnInNpc
		else
			TurnInLabel.Text = "  → Return to " .. Quest.TurnInNpc
		end
	end

	return QuestFrame
end

local function UpdateQuestFrame(QuestId: string, Objectives: {QuestObjective}, ReadyToTurnIn: boolean?, TurnInNpc: string?): ()
	local QuestFrame = QuestFrames[QuestId]
	if not QuestFrame then return end

	for Index, Objective in ipairs(Objectives) do
		local ObjectiveLabel = QuestFrame:FindFirstChild("Objective_" .. tostring(Index)) :: TextLabel?
		if ObjectiveLabel then
			local ExistingCompass = ObjectiveLabel:FindFirstChild("MiniCompass")
			local ProgressText = string.format("%d/%d", Objective.CurrentAmount, Objective.RequiredAmount)

			if Objective.Completed then
				ObjectiveLabel.Text = "  - " .. Objective.Description .. " (" .. ProgressText .. ")"
				ObjectiveLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
				ObjectiveLabel.TextStrokeTransparency = 0.8

				if ExistingCompass then
					ExistingCompass:Destroy()
				end
			else
				ObjectiveLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
				ObjectiveLabel.TextStrokeTransparency = 0.9

				if not ExistingCompass and Objective.Trackable ~= false and (Objective.Type == "Deliver" or Objective.Type == "TalkTo" or Objective.Type == "Interact") then
					if Objective.TargetId then
						local TargetPos = FindTargetPosition(Objective.Type, Objective.TargetId)
						if TargetPos then
							CreateMiniCompass(ObjectiveLabel, TargetPos, QuestId)
							ObjectiveLabel.Text = "      " .. Objective.Description .. " (" .. ProgressText .. ")"
						else
							ObjectiveLabel.Text = "  - " .. Objective.Description .. " (" .. ProgressText .. ")"
						end
					else
						ObjectiveLabel.Text = "  - " .. Objective.Description .. " (" .. ProgressText .. ")"
					end
				elseif ExistingCompass then
					ObjectiveLabel.Text = "      " .. Objective.Description .. " (" .. ProgressText .. ")"
				else
					ObjectiveLabel.Text = "  - " .. Objective.Description .. " (" .. ProgressText .. ")"
				end
			end
		end
	end

	local Title = QuestFrame:FindFirstChild("Title") :: TextLabel?
	local ExistingTurnInLabel = QuestFrame:FindFirstChild("TurnInLabel")

	if ReadyToTurnIn and TurnInNpc then
		if Title then
			Title.Text = "[TURN IN] " .. Title.Text:gsub("%[TURN IN%] ", "")
			Title.TextColor3 = Color3.fromRGB(100, 255, 255)
		end

		if not ExistingTurnInLabel then
			local TurnInLabel = Instance.new("TextLabel")
			TurnInLabel.Name = "TurnInLabel"
			TurnInLabel.LayoutOrder = #Objectives + 2
			TurnInLabel.Size = UDim2.new(1, 0, 0, 16)
			TurnInLabel.BackgroundTransparency = 1
			TurnInLabel.TextColor3 = Color3.fromRGB(255, 255, 100)
			TurnInLabel.TextScaled = true
			TurnInLabel.Font = Enum.Font.GothamBold
			TurnInLabel.TextXAlignment = Enum.TextXAlignment.Left
			TurnInLabel.TextTransparency = 1
			TurnInLabel.Parent = QuestFrame

			local TargetPos = FindTargetPosition("TalkTo", TurnInNpc)
			if TargetPos then
				CreateMiniCompass(TurnInLabel, TargetPos, QuestId)
				TurnInLabel.Text = "      Return to " .. TurnInNpc
			else
				TurnInLabel.Text = "  → Return to " .. TurnInNpc
			end

			TweenService:Create(TurnInLabel, TWEEN_INFO, {TextTransparency = 0}):Play()
		end
	elseif ExistingTurnInLabel then
		ExistingTurnInLabel:Destroy()
	end
end

local function AddQuest(Quest: Quest): ()
	if QuestFrames[Quest.Id] then return end

	local QuestFrame = CreateQuestFrame(Quest)
	QuestFrame.Parent = QuestContainer
	QuestFrames[Quest.Id] = QuestFrame

	QuestFrame.BackgroundTransparency = 1
	TweenService:Create(QuestFrame, TWEEN_INFO, {BackgroundTransparency = 0.3}):Play()
end

local function RemoveQuest(QuestId: string): ()
	local QuestFrame = QuestFrames[QuestId]
	if not QuestFrame then return end

	local BackgroundTween = TweenService:Create(QuestFrame, TWEEN_INFO, {BackgroundTransparency = 1})
	BackgroundTween:Play()

	for _, Descendant in ipairs(QuestFrame:GetDescendants()) do
		if Descendant:IsA("TextLabel") then
			TweenService:Create(Descendant, TWEEN_INFO, {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		elseif Descendant:IsA("ImageLabel") then
			TweenService:Create(Descendant, TWEEN_INFO, {ImageTransparency = 1}):Play()
		end
	end

	BackgroundTween.Completed:Connect(function()
		QuestFrame:Destroy()
	end)

	QuestFrames[QuestId] = nil
end

CreateQuestTracker()

UpdateQuestRemote.OnClientEvent:Connect(function(QuestId: string, Objectives: {QuestObjective}, ReadyToTurnIn: boolean?, TurnInNpc: string?)
	UpdateQuestFrame(QuestId, Objectives, ReadyToTurnIn, TurnInNpc)
end)

QuestStateChangedRemote.OnClientEvent:Connect(function(Action: string, Quest: Quest)
	if Action == "QuestAdded" then
		AddQuest(Quest)
	elseif Action == "QuestCompleted" then
		RemoveQuest(Quest.Id)
	elseif Action == "QuestReadyToTurnIn" then
		UpdateQuestFrame(Quest.Id, Quest.Objectives, Quest.ReadyToTurnIn, Quest.TurnInNpc)
	elseif Action == "QuestUpdated" then
		if Quest.Pinned then
			if not QuestFrames[Quest.Id] then
				AddQuest(Quest)
			else
				UpdateQuestFrame(Quest.Id, Quest.Objectives, Quest.ReadyToTurnIn, Quest.TurnInNpc)
			end
		else
			RemoveQuest(Quest.Id)
		end
	end
end)

RunService.RenderStepped:Connect(UpdateCompassRotations)

print("[QuestUIClient] Quest tracker initialized")