--!strict
local FeedbackUI = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Constants
local FEEDBACK_DURATION = 2.5
local FADE_IN_TIME = 0.2
local FADE_OUT_TIME = 0.3
local MAX_ACTIVE_MESSAGES = 3

-- Message types with colors
local MESSAGE_TYPES = {
	Error = Color3.fromRGB(255, 100, 100),    -- Red
	Warning = Color3.fromRGB(255, 200, 100),  -- Orange
	Info = Color3.fromRGB(100, 200, 255),     -- Blue
	Success = Color3.fromRGB(100, 255, 100),  -- Green
}

type MessageType = "Error" | "Warning" | "Info" | "Success"

type FeedbackMessage = {
	Frame: Frame,
	Label: TextLabel,
	CreatedAt: number,
	Duration: number,
}

-- Active messages queue
local ActiveMessages: {FeedbackMessage} = {}
local FeedbackContainer: ScreenGui? = nil

-- Create the container ScreenGui
local function CreateContainer(): ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "FeedbackUI"
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 100
	screenGui.IgnoreGuiInset = true
	screenGui.Parent = PlayerGui

	return screenGui
end

-- Get or create container
local function GetContainer(): ScreenGui
	if not FeedbackContainer or not FeedbackContainer.Parent then
		FeedbackContainer = CreateContainer()
	end
	return FeedbackContainer
end

-- Update message positions (stack vertically)
local function UpdateMessagePositions()
	local yOffset = 0
	local spacing = 10

	for i, msg in ipairs(ActiveMessages) do
		local targetPosition = UDim2.new(0.5, 0, 0, 100 + yOffset)

		local tween = TweenService:Create(
			msg.Frame,
			TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = targetPosition}
		)
		tween:Play()

		yOffset += msg.Frame.AbsoluteSize.Y + spacing
	end
end

-- Remove a message
local function RemoveMessage(msg: FeedbackMessage)
	-- Find and remove from active list
	local index = table.find(ActiveMessages, msg)
	if index then
		table.remove(ActiveMessages, index)
	end

	-- Fade out
	local fadeOut = TweenService:Create(
		msg.Frame,
		TweenInfo.new(FADE_OUT_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{
			BackgroundTransparency = 1,
			Position = msg.Frame.Position + UDim2.new(0, 0, 0, -20)
		}
	)

	local labelFadeOut = TweenService:Create(
		msg.Label,
		TweenInfo.new(FADE_OUT_TIME),
		{TextTransparency = 1}
	)

	fadeOut:Play()
	labelFadeOut:Play()

	fadeOut.Completed:Connect(function()
		msg.Frame:Destroy()
	end)

	UpdateMessagePositions()
end

-- Create a feedback message
local function CreateMessage(text: string, messageType: MessageType, duration: number?): FeedbackMessage
	local container = GetContainer()

	-- Enforce max messages
	if #ActiveMessages >= MAX_ACTIVE_MESSAGES then
		RemoveMessage(ActiveMessages[1])
	end

	-- Create frame
	local frame = Instance.new("Frame")
	frame.Name = "FeedbackMessage"
	frame.Size = UDim2.new(0, 400, 0, 60)
	frame.Position = UDim2.new(0.5, 0, 0, 80)
	frame.AnchorPoint = Vector2.new(0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = container

	-- Rounded corners
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = MESSAGE_TYPES[messageType]
	stroke.Thickness = 2
	stroke.Parent = frame

	-- Drop shadow
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.7
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 10, 10)
	shadow.ZIndex = -1
	shadow.Parent = frame

	-- Text label
	local label = Instance.new("TextLabel")
	label.Name = "MessageLabel"
	label.Size = UDim2.new(1, -20, 1, 0)
	label.Position = UDim2.new(0, 10, 0, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextSize = 18
	label.Font = Enum.Font.GothamMedium
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTransparency = 1
	label.Parent = frame

	-- Icon (optional based on type)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 30, 0, 30)
	icon.Position = UDim2.new(0, 10, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.BackgroundTransparency = 1
	icon.TextColor3 = MESSAGE_TYPES[messageType]
	icon.TextSize = 24
	icon.Font = Enum.Font.GothamBold
	icon.Text = messageType == "Error" and "✖" 
		or messageType == "Warning" and "⚠" 
		or messageType == "Success" and "✔" 
		or "ℹ"
	icon.TextTransparency = 1
	icon.Parent = frame

	-- Adjust label position for icon
	label.Position = UDim2.new(0, 45, 0, 0)
	label.Size = UDim2.new(1, -55, 1, 0)

	-- Create message data
	local msg: FeedbackMessage = {
		Frame = frame,
		Label = label,
		CreatedAt = tick(),
		Duration = duration or FEEDBACK_DURATION,
	}

	table.insert(ActiveMessages, msg)

	-- Fade in
	local fadeIn = TweenService:Create(
		frame,
		TweenInfo.new(FADE_IN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.1}
	)

	local labelFadeIn = TweenService:Create(
		label,
		TweenInfo.new(FADE_IN_TIME),
		{TextTransparency = 0}
	)

	local iconFadeIn = TweenService:Create(
		icon,
		TweenInfo.new(FADE_IN_TIME),
		{TextTransparency = 0}
	)

	fadeIn:Play()
	labelFadeIn:Play()
	iconFadeIn:Play()

	UpdateMessagePositions()

	-- Auto-remove after duration
	task.delay(msg.Duration, function()
		if table.find(ActiveMessages, msg) then
			RemoveMessage(msg)
		end
	end)

	return msg
end

-- Public API
function FeedbackUI.ShowError(text: string, duration: number?): ()
	CreateMessage(text, "Error", duration)
end

function FeedbackUI.ShowWarning(text: string, duration: number?): ()
	CreateMessage(text, "Warning", duration)
end

function FeedbackUI.ShowInfo(text: string, duration: number?): ()
	CreateMessage(text, "Info", duration)
end

function FeedbackUI.ShowSuccess(text: string, duration: number?): ()
	CreateMessage(text, "Success", duration)
end

-- Generic show with custom type
function FeedbackUI.Show(text: string, messageType: MessageType?, duration: number?): ()
	CreateMessage(text, messageType or "Info", duration)
end

-- Clear all active messages
function FeedbackUI.ClearAll(): ()
	for _, msg in ipairs(ActiveMessages) do
		RemoveMessage(msg)
	end
end

return FeedbackUI