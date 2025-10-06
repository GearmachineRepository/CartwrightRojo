--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogNode = DialogTree.DialogNode

local NodeRenderer = {}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local NODE_WIDTH = 220
local NODE_HEIGHT = 100
local PORT_SIZE = 12

local function CreatePort(IsOutput: boolean, Parent: Frame, YOffset: number?, Index: number?): Frame
	local Port = Instance.new("Frame")
	Port.Size = UDim2.fromOffset(PORT_SIZE, PORT_SIZE)
	Port.AnchorPoint = Vector2.new(0.5, 0.5)
	Port.BackgroundColor3 = Constants.COLORS.Primary
	Port.BorderSizePixel = 1
	Port.BorderColor3 = Constants.COLORS.BackgroundDark
	Port.ZIndex = 5
	Port.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(1, 0)
	Corner.Parent = Port

	if IsOutput then
		Port.Name = ("OutputPort_%d"):format(Index or 1)
		-- outside the right edge (Blender-style)
		Port.Position = UDim2.new(1, PORT_SIZE/2, 0, YOffset or NODE_HEIGHT/2)
	else
		Port.Name = "InputPort"
		-- outside the left edge
		Port.Position = UDim2.new(0, -PORT_SIZE/2, 0.5, 0)
	end

	return Port
end

function NodeRenderer.CreateNode(
	Node: DialogNode,
	Position: UDim2,
	IsSelected: boolean,
	OnNodeSelected: (DialogNode) -> (),
	OnDragStarted: (Frame) -> (),
	OnDragEnded: (Frame) -> ()
): Frame
	local NodeFrame = Instance.new("Frame")
	NodeFrame.Name = Node.Id or "Node"
	NodeFrame.Size = UDim2.fromOffset(NODE_WIDTH, NODE_HEIGHT)
	NodeFrame.Position = Position
	NodeFrame.BackgroundColor3 = IsSelected and Constants.COLORS.SelectedBg or Constants.COLORS.Panel
	NodeFrame.BorderSizePixel = 0
	NodeFrame.ZIndex = 3

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = IsSelected and Constants.COLORS.Primary or Constants.COLORS.Border
	Stroke.Thickness = IsSelected and 2 or 1
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = NodeFrame

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = NodeFrame

	local TitleBar = Instance.new("Frame")
	TitleBar.Size = UDim2.new(1, 0, 0, 32)
	TitleBar.BackgroundColor3 = IsSelected and Constants.COLORS.PrimaryDark or Constants.COLORS.BackgroundDark
	TitleBar.BorderSizePixel = 0
	TitleBar.ZIndex = 4
	TitleBar.Parent = NodeFrame

	local TitleCorner = Instance.new("UICorner")
	TitleCorner.CornerRadius = UDim.new(0, 8)
	TitleCorner.Parent = TitleBar

	local TitleCover = Instance.new("Frame")
	TitleCover.Size = UDim2.new(1, 0, 0, 16)
	TitleCover.Position = UDim2.fromOffset(0, 16)
	TitleCover.BackgroundColor3 = IsSelected and Constants.COLORS.PrimaryDark or Constants.COLORS.BackgroundDark
	TitleCover.BorderSizePixel = 0
	TitleCover.ZIndex = 4
	TitleCover.Parent = TitleBar

	local TitleLabel = Instance.new("TextLabel")
	TitleLabel.Size = UDim2.fromScale(1, 1)
	TitleLabel.Text = Node.Id or "Node"
	TitleLabel.TextColor3 = Constants.COLORS.TextPrimary
	TitleLabel.BackgroundTransparency = 1
	TitleLabel.Font = Constants.FONTS.Bold
	TitleLabel.TextSize = Constants.TEXT_SIZES.Normal
	TitleLabel.ZIndex = 5
	TitleLabel.Parent = TitleBar

	local ContentLabel = Instance.new("TextLabel")
	ContentLabel.Size = UDim2.new(1, -16, 1, -40)
	ContentLabel.Position = UDim2.fromOffset(8, 36)
	ContentLabel.Text = Node.Text:sub(1, 60) .. (Node.Text:len() > 60 and "..." or "")
	ContentLabel.TextColor3 = Constants.COLORS.TextSecondary
	ContentLabel.BackgroundTransparency = 1
	ContentLabel.Font = Constants.FONTS.Regular
	ContentLabel.TextSize = Constants.TEXT_SIZES.Small
	ContentLabel.TextWrapped = true
	ContentLabel.TextXAlignment = Enum.TextXAlignment.Left
	ContentLabel.TextYAlignment = Enum.TextYAlignment.Top
	ContentLabel.ZIndex = 4
	ContentLabel.Parent = NodeFrame

    CreatePort(false, NodeFrame) -- input

    if Node.Choices and #Node.Choices > 0 then
        local PortSpacing = NODE_HEIGHT / (#Node.Choices + 1)
        for i = 1, #Node.Choices do
            CreatePort(true, NodeFrame, PortSpacing * i, i)
        end
    else
        CreatePort(true, NodeFrame, NODE_HEIGHT/2, 1)
    end

	local Dragger = Instance.new("TextButton")
	Dragger.Size = UDim2.fromScale(1, 1)
	Dragger.BackgroundTransparency = 1
	Dragger.Text = ""
	Dragger.ZIndex = 6
	Dragger.Parent = NodeFrame

	Dragger.MouseEnter:Connect(function()
		if not IsSelected then
			TweenService:Create(NodeFrame, TWEEN_INFO, {
				BackgroundColor3 = Constants.COLORS.PanelHover
			}):Play()
		end
	end)

	Dragger.MouseLeave:Connect(function()
		if not IsSelected then
			TweenService:Create(NodeFrame, TWEEN_INFO, {
				BackgroundColor3 = Constants.COLORS.Panel
			}):Play()
		end
	end)

	Dragger.MouseButton1Click:Connect(function()
		OnNodeSelected(Node)
	end)

	Dragger.MouseButton1Down:Connect(function()
		OnDragStarted(NodeFrame)
	end)

	Dragger.MouseButton1Up:Connect(function()
		OnDragEnded(NodeFrame)
	end)

	return NodeFrame
end

function NodeRenderer.GetNodeSize(): Vector2
	return Vector2.new(NODE_WIDTH, NODE_HEIGHT)
end

function NodeRenderer.GetPortSize(): number
	return PORT_SIZE
end

return NodeRenderer