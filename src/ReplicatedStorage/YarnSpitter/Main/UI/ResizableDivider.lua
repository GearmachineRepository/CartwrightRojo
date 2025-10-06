--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local ResizableDivider = {}

local TWEEN_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local MIN_PANEL_WIDTH = 200
local DIVIDER_WIDTH = 4

local CurrentDividerPosition: number = 0.25

type UpdateCallback = (number) -> ()

function ResizableDivider.Create(Parent: Instance, OnPositionChanged: UpdateCallback): Frame
	local Divider = Instance.new("Frame")
	Divider.Size = UDim2.new(0, DIVIDER_WIDTH, 1, -Constants.SIZES.TopBarHeight - 10)
	Divider.Position = UDim2.new(CurrentDividerPosition, -DIVIDER_WIDTH / 2, 0, Constants.SIZES.TopBarHeight + 5)
	Divider.BackgroundColor3 = Constants.COLORS.Border
	Divider.BorderSizePixel = 0
	Divider.ZIndex = 10
	Divider.Parent = Parent

	local HoverIndicator = Instance.new("Frame")
	HoverIndicator.Size = UDim2.new(1, 8, 1, 0)
	HoverIndicator.Position = UDim2.fromOffset(-4, 0)
	HoverIndicator.BackgroundTransparency = 1
	HoverIndicator.Parent = Divider

	local DragButton = Instance.new("TextButton")
	DragButton.Size = UDim2.fromScale(1, 1)
	DragButton.BackgroundTransparency = 1
	DragButton.Text = ""
	DragButton.AutoButtonColor = false
	DragButton.ZIndex = 11
	DragButton.Parent = HoverIndicator

	local IsHovering = false
	local IsDragging = false
	local DragConnection: RBXScriptConnection? = nil

	local function UpdateDividerAppearance()
		local TargetColor = if IsDragging then Constants.COLORS.Primary
			elseif IsHovering then Constants.COLORS.BorderLight
			else Constants.COLORS.Border

		TweenService:Create(Divider, TWEEN_INFO, {
			BackgroundColor3 = TargetColor
		}):Play()
	end

	local function StopDragging()
		if DragConnection then
			DragConnection:Disconnect()
			DragConnection = nil
		end
		IsDragging = false
		UpdateDividerAppearance()
	end

	DragButton.MouseEnter:Connect(function()
		IsHovering = true
		UpdateDividerAppearance()
	end)

	DragButton.MouseLeave:Connect(function()
		IsHovering = false
		UpdateDividerAppearance()
	end)

	DragButton.InputBegan:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			IsDragging = true
			UpdateDividerAppearance()
		elseif not DragConnection and Input.UserInputType == Enum.UserInputType.MouseMovement then
			DragConnection = RunService.Heartbeat:Connect(function()
				if not IsDragging then
					return
				end

				local ParentSize = Parent.AbsoluteSize.X
				local ParentPosX = Parent.AbsolutePosition.X
				local MouseX = Input.Position.X
				local RelativeX = MouseX - ParentPosX
				local NewPosition = RelativeX / ParentSize

				local MinScale = MIN_PANEL_WIDTH / ParentSize
				local MaxScale = 1 - (MIN_PANEL_WIDTH / ParentSize)

				NewPosition = math.clamp(NewPosition, MinScale, MaxScale)

				CurrentDividerPosition = NewPosition
				Divider.Position = UDim2.new(NewPosition, -DIVIDER_WIDTH / 2, 0, Constants.SIZES.TopBarHeight + 5)

				OnPositionChanged(NewPosition)
			end)
		end
	end)

	DragButton.InputEnded:Connect(function(Input: InputObject)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			StopDragging()
		end
	end)

	return Divider
end

function ResizableDivider.GetCurrentPosition(): number
	return CurrentDividerPosition
end

function ResizableDivider.SetPosition(Position: number)
	CurrentDividerPosition = math.clamp(Position, 0.15, 0.85)
end

return ResizableDivider