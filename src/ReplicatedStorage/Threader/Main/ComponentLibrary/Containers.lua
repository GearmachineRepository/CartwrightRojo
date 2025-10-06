--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")

local Containers = {}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local CollapsibleStates: {[string]: boolean} = {}

local function CreateTween(Instance: GuiObject, Properties: {[string]: any})
	return TweenService:Create(Instance, TWEEN_INFO, Properties)
end

function Containers.CreateContainer(Parent: Instance, Order: number): Frame
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 100)
	Container.BackgroundColor3 = Constants.COLORS.Card
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Container

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 8)
	Layout.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 12)
	Padding.PaddingRight = UDim.new(0, 12)
	Padding.PaddingTop = UDim.new(0, 12)
	Padding.PaddingBottom = UDim.new(0, 12)
	Padding.Parent = Container

	local function UpdateSize()
		local ContentHeight = Layout.AbsoluteContentSize.Y + 24
		if ContentHeight < 50 then
			ContentHeight = 50
		end
		Container.Size = UDim2.new(1, 0, 0, ContentHeight)
	end

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSize)

	task.defer(UpdateSize)

	return Container
end

function Containers.CreateCollapsibleSection(
	Title: string,
	Parent: Instance,
	Order: number,
	StartCollapsed: boolean?
): (Frame, Frame)
	local StateKey = tostring(Parent) .. "_" .. Title
	local IsCollapsed = CollapsibleStates[StateKey]
	if IsCollapsed == nil then
		IsCollapsed = StartCollapsed or false
		CollapsibleStates[StateKey] = IsCollapsed
	end

	local Section = Instance.new("Frame")
	Section.Size = UDim2.new(1, 0, 0, 36)
	Section.BackgroundTransparency = 1
	Section.LayoutOrder = Order
	Section.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, 6)
	Layout.Parent = Section

	local Header = Instance.new("TextButton")
	Header.Size = UDim2.new(1, 0, 0, 32)
	Header.BackgroundColor3 = Constants.COLORS.PanelHover
	Header.BorderSizePixel = 0
	Header.Text = ""
	Header.AutoButtonColor = false
	Header.LayoutOrder = 1
	Header.Parent = Section

	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, 6)
	HeaderCorner.Parent = Header

	local Arrow = Instance.new("TextLabel")
	Arrow.Size = UDim2.fromOffset(20, 20)
	Arrow.Position = UDim2.fromOffset(8, 6)
	Arrow.Text = "▼"
	Arrow.TextColor3 = Constants.COLORS.TextSecondary
	Arrow.BackgroundTransparency = 1
	Arrow.Font = Constants.FONTS.Regular
	Arrow.TextSize = 12
	Arrow.Rotation = IsCollapsed and -90 or 0
	Arrow.Parent = Header

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.new(1, -36, 1, 0)
	TitleLabel.Position = UDim2.fromOffset(32, 0)
	TitleLabel.Text = Title
	TitleLabel.TextColor3 = Constants.COLORS.TextPrimary
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = Constants.FONTS.Medium
	TitleLabel.TextSize = 14
	TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
	TitleLabel.Parent = Header

	local Content = Instance.new("Frame")
	Content.Size = UDim2.fromScale(1, 0)
	Content.BackgroundTransparency = 1
	Content.Visible = not IsCollapsed
	Content.LayoutOrder = 2
	Content.Parent = Section

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, 6)
	ContentLayout.Parent = Content

	local function UpdateSizes()
		local ContentHeight = ContentLayout.AbsoluteContentSize.Y
		Content.Size = UDim2.new(1, 0, 0, ContentHeight)
		Section.Size = UDim2.new(1, 0, 0, 38 + (Content.Visible and ContentHeight or 0))
	end

	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(UpdateSizes)

	task.defer(UpdateSizes)

	Header.MouseEnter:Connect(function()
		CreateTween(Header, {BackgroundColor3 = Constants.COLORS.Panel}):Play()
	end)

	Header.MouseLeave:Connect(function()
		CreateTween(Header, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	Header.MouseButton1Click:Connect(function()
		Content.Visible = not Content.Visible
		CollapsibleStates[StateKey] = not Content.Visible
		CreateTween(Arrow, {Rotation = Content.Visible and 0 or -90}):Play()
		UpdateSizes()
	end)

	return Section, Content
end

return Containers