--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")

local Prompt = {}

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ActivePrompt: ScreenGui? = nil

type TextInputCallback = (string) -> ()
type ConfirmCallback = (boolean) -> ()
type SelectionCallback = (string) -> ()

local function ClosePrompt()
	if ActivePrompt then
		local Overlay = ActivePrompt:FindFirstChild("Overlay")
		local Dialog = ActivePrompt:FindFirstChild("Dialog")

		if Overlay and Dialog then
			TweenService:Create(Overlay, TWEEN_INFO, {BackgroundTransparency = 1}):Play()
			TweenService:Create(Dialog, TWEEN_INFO, {Position = UDim2.fromScale(0.5, 0.4)}):Play()
		end

		task.wait(0.2)
		ActivePrompt:Destroy()
		ActivePrompt = nil
	end
end

local function CreateOverlay(Parent: Instance): Frame
	local Overlay = Instance.new("Frame")
	Overlay.Name = "Overlay"
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Overlay.BackgroundTransparency = 1
	Overlay.BorderSizePixel = 0
	Overlay.ZIndex = 10000
	Overlay.Parent = Parent

	TweenService:Create(Overlay, TWEEN_INFO, {BackgroundTransparency = 0.7}):Play()

	return Overlay
end

local function CreateDialogBase(Parent: Instance, Title: string, Width: number, Height: number): Frame
	local Dialog = Instance.new("Frame")
	Dialog.Name = "Dialog"
	Dialog.Size = UDim2.fromOffset(Width, Height)
	Dialog.Position = UDim2.fromScale(0.5, 0.4)
	Dialog.AnchorPoint = Vector2.new(0.5, 0.5)
	Dialog.BackgroundColor3 = Constants.COLORS.BackgroundLight
	Dialog.BorderSizePixel = 0
	Dialog.ZIndex = 10001
	Dialog.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Dialog

	local TitleBar = Instance.new("Frame")
	TitleBar.Size = UDim2.new(1, 0, 0, 40)
	TitleBar.BackgroundColor3 = Constants.COLORS.BackgroundDark
	TitleBar.BorderSizePixel = 0
	TitleBar.ZIndex = 10002
	TitleBar.Parent = Dialog

	local TitleCorner = Instance.new("UICorner")
	TitleCorner.CornerRadius = UDim.new(0, 8)
	TitleCorner.Parent = TitleBar

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -20, 1, 0)
	TitleLabel.Position = UDim2.fromOffset(20, 0)
	TitleLabel.Text = Title
	TitleLabel.TextColor3 = Constants.COLORS.TextPrimary
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = Constants.FONTS.Bold
	TitleLabel.TextSize = 16
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.ZIndex = 10003
	TitleLabel.Parent = TitleBar

	TweenService:Create(Dialog, TWEEN_INFO, {Position = UDim2.fromScale(0.5, 0.5)}):Play()

	return Dialog
end

function Prompt.CreateTextInput(
	Parent: Instance,
	Title: string,
	PlaceholderText: string,
	DefaultValue: string?,
	OnConfirm: TextInputCallback,
	OnCancel: (() -> ())?
)
	if ActivePrompt then
		ClosePrompt()
	end

	local PromptGui = Instance.new("Frame")
	PromptGui.Name = "PromptGui"
	PromptGui.Size = UDim2.fromScale(1, 1)
	PromptGui.BackgroundTransparency = 1
	PromptGui.ZIndex = 10000
	PromptGui.Parent = Parent
	ActivePrompt = PromptGui

	CreateOverlay(PromptGui)
	local Dialog = CreateDialogBase(PromptGui, Title, 400, 160)

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Size = UDim2.new(1, -40, 1, -100)
	ContentFrame.Position = UDim2.fromOffset(20, 50)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.ZIndex = 10002
	ContentFrame.Parent = Dialog

	local TextBox = Instance.new("TextBox")
	TextBox.Size = UDim2.new(1, 0, 0, 40)
	TextBox.Text = DefaultValue or ""
	TextBox.PlaceholderText = PlaceholderText
	TextBox.TextColor3 = Constants.COLORS.TextPrimary
	TextBox.PlaceholderColor3 = Constants.COLORS.TextMuted
	TextBox.BackgroundColor3 = Constants.COLORS.InputBackground
	TextBox.BorderSizePixel = 1
	TextBox.BorderColor3 = Constants.COLORS.InputBorder
	TextBox.Font = Constants.FONTS.Regular
	TextBox.TextSize = 14
	TextBox.ClearTextOnFocus = false
	TextBox.ZIndex = 10003
	TextBox.Parent = ContentFrame

	local TextCorner = Instance.new("UICorner")
	TextCorner.CornerRadius = UDim.new(0, 6)
	TextCorner.Parent = TextBox

	local TextPadding = Instance.new("UIPadding")
	TextPadding.PaddingLeft = UDim.new(0, 10)
	TextPadding.PaddingRight = UDim.new(0, 10)
	TextPadding.Parent = TextBox

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Size = UDim2.new(1, -40, 0, 40)
	ButtonContainer.Position = UDim2.new(0, 20, 1, -50)
	ButtonContainer.BackgroundTransparency = 1
	ButtonContainer.ZIndex = 1002
	ButtonContainer.Parent = Dialog

	local ButtonLayout = Instance.new("UIListLayout")
	ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ButtonLayout.Padding = UDim.new(0, 10)
	ButtonLayout.Parent = ButtonContainer

	local CancelButton = Instance.new("TextButton")
	CancelButton.Size = UDim2.fromOffset(100, 40)
	CancelButton.Text = "Cancel"
	CancelButton.TextColor3 = Constants.COLORS.TextPrimary
	CancelButton.BackgroundColor3 = Constants.COLORS.Panel
	CancelButton.Font = Constants.FONTS.Medium
	CancelButton.TextSize = 14
	CancelButton.BorderSizePixel = 0
	CancelButton.AutoButtonColor = false
	CancelButton.ZIndex = 10004
	CancelButton.Parent = ButtonContainer

	local CancelCorner = Instance.new("UICorner")
	CancelCorner.CornerRadius = UDim.new(0, 6)
	CancelCorner.Parent = CancelButton

	local ConfirmButton = Instance.new("TextButton")
	ConfirmButton.Size = UDim2.fromOffset(100, 40)
	ConfirmButton.Text = "Create"
	ConfirmButton.TextColor3 = Constants.COLORS.TextPrimary
	ConfirmButton.BackgroundColor3 = Constants.COLORS.Primary
	ConfirmButton.Font = Constants.FONTS.Medium
	ConfirmButton.TextSize = 14
	ConfirmButton.BorderSizePixel = 0
	ConfirmButton.AutoButtonColor = false
	ConfirmButton.ZIndex = 10004
	ConfirmButton.Parent = ButtonContainer

	local ConfirmCorner = Instance.new("UICorner")
	ConfirmCorner.CornerRadius = UDim.new(0, 6)
	ConfirmCorner.Parent = ConfirmButton

	TextBox.Focused:Connect(function()
		TweenService:Create(TextBox, TWEEN_INFO, {BorderColor3 = Constants.COLORS.Primary}):Play()
	end)

	TextBox.FocusLost:Connect(function()
		TweenService:Create(TextBox, TWEEN_INFO, {BorderColor3 = Constants.COLORS.InputBorder}):Play()
	end)

	CancelButton.MouseEnter:Connect(function()
		TweenService:Create(CancelButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	CancelButton.MouseLeave:Connect(function()
		TweenService:Create(CancelButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.Panel}):Play()
	end)

	ConfirmButton.MouseEnter:Connect(function()
		TweenService:Create(ConfirmButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.PrimaryHover}):Play()
	end)

	ConfirmButton.MouseLeave:Connect(function()
		TweenService:Create(ConfirmButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.Primary}):Play()
	end)

	CancelButton.MouseButton1Click:Connect(function()
		ClosePrompt()
		if OnCancel then
			OnCancel()
		end
	end)

	ConfirmButton.MouseButton1Click:Connect(function()
		local Value = TextBox.Text
		ClosePrompt()
		OnConfirm(Value)
	end)

	TextBox:CaptureFocus()
end

function Prompt.CreateConfirmation(
	Parent: Instance,
	Title: string,
	Message: string,
	ConfirmText: string,
	OnConfirm: ConfirmCallback
)
	if ActivePrompt then
		ClosePrompt()
	end

	local PromptGui = Instance.new("Frame")
	PromptGui.Name = "PromptGui"
	PromptGui.Size = UDim2.fromScale(1, 1)
	PromptGui.BackgroundTransparency = 1
	PromptGui.ZIndex = 10000
	PromptGui.Parent = Parent
	ActivePrompt = PromptGui

	CreateOverlay(PromptGui)
	local Dialog = CreateDialogBase(PromptGui, Title, 400, 180)

	local MessageLabel = Instance.new("TextLabel")
	MessageLabel.Size = UDim2.new(1, -40, 0, 60)
	MessageLabel.Position = UDim2.fromOffset(20, 50)
	MessageLabel.Text = Message
	MessageLabel.TextColor3 = Constants.COLORS.TextSecondary
	MessageLabel.BackgroundTransparency = 1
	MessageLabel.Font = Constants.FONTS.Regular
	MessageLabel.TextSize = 14
	MessageLabel.TextWrapped = true
	MessageLabel.TextXAlignment = Enum.TextXAlignment.Left
	MessageLabel.TextYAlignment = Enum.TextYAlignment.Top
	MessageLabel.ZIndex = 10003
	MessageLabel.Parent = Dialog

	local ButtonContainer = Instance.new("Frame")
	ButtonContainer.Size = UDim2.new(1, -40, 0, 40)
	ButtonContainer.Position = UDim2.new(0, 20, 1, -50)
	ButtonContainer.BackgroundTransparency = 1
	ButtonContainer.ZIndex = 10004  -- Changed from 10002
	ButtonContainer.Parent = Dialog

	local ButtonLayout = Instance.new("UIListLayout")
	ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	ButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ButtonLayout.Padding = UDim.new(0, 10)
	ButtonLayout.Parent = ButtonContainer

	local CancelButton = Instance.new("TextButton")
	CancelButton.Size = UDim2.fromOffset(100, 40)
	CancelButton.Text = "Cancel"
	CancelButton.TextColor3 = Constants.COLORS.TextPrimary
	CancelButton.BackgroundColor3 = Constants.COLORS.Panel
	CancelButton.Font = Constants.FONTS.Medium
	CancelButton.TextSize = 14
	CancelButton.BorderSizePixel = 0
	CancelButton.AutoButtonColor = false
	CancelButton.ZIndex = 10005  -- Changed from 1003
	CancelButton.Parent = ButtonContainer

	local CancelCorner = Instance.new("UICorner")
	CancelCorner.CornerRadius = UDim.new(0, 6)
	CancelCorner.Parent = CancelButton

	local ConfirmButton = Instance.new("TextButton")
	ConfirmButton.Size = UDim2.fromOffset(100, 40)
	ConfirmButton.Text = ConfirmText
	ConfirmButton.TextColor3 = Constants.COLORS.TextPrimary
	ConfirmButton.BackgroundColor3 = Constants.COLORS.Danger
	ConfirmButton.Font = Constants.FONTS.Medium
	ConfirmButton.TextSize = 14
	ConfirmButton.BorderSizePixel = 0
	ConfirmButton.AutoButtonColor = false
	ConfirmButton.ZIndex = 10005  -- Changed from 1003
	ConfirmButton.Parent = ButtonContainer

	local ConfirmCorner = Instance.new("UICorner")
	ConfirmCorner.CornerRadius = UDim.new(0, 6)
	ConfirmCorner.Parent = ConfirmButton

	CancelButton.MouseEnter:Connect(function()
		TweenService:Create(CancelButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	CancelButton.MouseLeave:Connect(function()
		TweenService:Create(CancelButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.Panel}):Play()
	end)

	ConfirmButton.MouseEnter:Connect(function()
		TweenService:Create(ConfirmButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.DangerHover}):Play()
	end)

	ConfirmButton.MouseLeave:Connect(function()
		TweenService:Create(ConfirmButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.Danger}):Play()
	end)

	CancelButton.MouseButton1Click:Connect(function()
		ClosePrompt()
		OnConfirm(false)
	end)

	ConfirmButton.MouseButton1Click:Connect(function()
		ClosePrompt()
		OnConfirm(true)
	end)
end

function Prompt.CreateSelection(
	Parent: Instance,
	Title: string,
	Options: {string},
	OnSelect: SelectionCallback,
	OnCancel: (() -> ())?
)
	if ActivePrompt then
		ClosePrompt()
	end

	local PromptGui = Instance.new("ScreenGui")
	PromptGui.Name = "PromptGui"
	PromptGui.DisplayOrder = 1000
	PromptGui.Parent = Parent
	ActivePrompt = PromptGui

	CreateOverlay(PromptGui)
	local DialogHeight = math.min(400, 120 + (#Options * 40) + 20)
	local Dialog = CreateDialogBase(PromptGui, Title, 400, DialogHeight)

	local ListFrame = Instance.new("ScrollingFrame")
	ListFrame.Size = UDim2.new(1, -40, 1, -110)
	ListFrame.Position = UDim2.fromOffset(20, 50)
	ListFrame.BackgroundColor3 = Constants.COLORS.Background
	ListFrame.BorderSizePixel = 0
	ListFrame.ScrollBarThickness = 6
	ListFrame.ZIndex = 1002
	ListFrame.Parent = Dialog

	local ListCorner = Instance.new("UICorner")
	ListCorner.CornerRadius = UDim.new(0, 6)
	ListCorner.Parent = ListFrame

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.Padding = UDim.new(0, 4)
	ListLayout.Parent = ListFrame

	local ListPadding = Instance.new("UIPadding")
	ListPadding.PaddingLeft = UDim.new(0, 8)
	ListPadding.PaddingRight = UDim.new(0, 8)
	ListPadding.PaddingTop = UDim.new(0, 8)
	ListPadding.PaddingBottom = UDim.new(0, 8)
	ListPadding.Parent = ListFrame

	for _, Option in ipairs(Options) do
		local OptionButton = Instance.new("TextButton")
		OptionButton.Size = UDim2.new(1, 0, 0, 36)
		OptionButton.Text = Option
		OptionButton.TextColor3 = Constants.COLORS.TextPrimary
		OptionButton.BackgroundColor3 = Constants.COLORS.Panel
		OptionButton.Font = Constants.FONTS.Regular
		OptionButton.TextSize = 14
		OptionButton.TextXAlignment = Enum.TextXAlignment.Left
		OptionButton.BorderSizePixel = 0
		OptionButton.AutoButtonColor = false
		OptionButton.ZIndex = 1003
		OptionButton.Parent = ListFrame

		local OptionCorner = Instance.new("UICorner")
		OptionCorner.CornerRadius = UDim.new(0, 6)
		OptionCorner.Parent = OptionButton

		local OptionPadding = Instance.new("UIPadding")
		OptionPadding.PaddingLeft = UDim.new(0, 12)
		OptionPadding.PaddingRight = UDim.new(0, 12)
		OptionPadding.Parent = OptionButton

		OptionButton.MouseEnter:Connect(function()
			TweenService:Create(OptionButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
		end)

		OptionButton.MouseLeave:Connect(function()
			TweenService:Create(OptionButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.Panel}):Play()
		end)

		OptionButton.MouseButton1Click:Connect(function()
			ClosePrompt()
			OnSelect(Option)
		end)
	end

	ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ListFrame.CanvasSize = UDim2.fromOffset(0, ListLayout.AbsoluteContentSize.Y + 16)
	end)

	local CancelButton = Instance.new("TextButton")
	CancelButton.Size = UDim2.fromOffset(100, 40)
	CancelButton.Position = UDim2.new(1, -120, 1, -50)
	CancelButton.Text = "Cancel"
	CancelButton.TextColor3 = Constants.COLORS.TextPrimary
	CancelButton.BackgroundColor3 = Constants.COLORS.Panel
	CancelButton.Font = Constants.FONTS.Medium
	CancelButton.TextSize = 14
	CancelButton.BorderSizePixel = 0
	CancelButton.AutoButtonColor = false
	CancelButton.ZIndex = 1003
	CancelButton.Parent = Dialog

	local CancelCorner = Instance.new("UICorner")
	CancelCorner.CornerRadius = UDim.new(0, 6)
	CancelCorner.Parent = CancelButton

	CancelButton.MouseEnter:Connect(function()
		TweenService:Create(CancelButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	CancelButton.MouseLeave:Connect(function()
		TweenService:Create(CancelButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.Panel}):Play()
	end)

	CancelButton.MouseButton1Click:Connect(function()
		ClosePrompt()
		if OnCancel then
			OnCancel()
		end
	end)
end

return Prompt