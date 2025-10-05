--!strict
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local TweenService = game:GetService("TweenService")

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local TreeView = {}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function TreeView.Create(Parent: Instance): ScrollingFrame
	local TreeScrollFrame = Instance.new("ScrollingFrame")
	TreeScrollFrame.Size = UDim2.new(Constants.SIZES.TreeViewWidth, -10, 1, -Constants.SIZES.TopBarHeight - 10)
	TreeScrollFrame.Position = UDim2.fromOffset(10, Constants.SIZES.TopBarHeight + 5)
	TreeScrollFrame.BackgroundColor3 = Constants.COLORS.BackgroundLight
	TreeScrollFrame.BorderSizePixel = 0
	TreeScrollFrame.ScrollBarThickness = Constants.SIZES.ScrollBarThickness
	TreeScrollFrame.CanvasSize = UDim2.fromOffset(500, 0)
	TreeScrollFrame.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	Corner.Parent = TreeScrollFrame

	local TreeLayout = Instance.new("UIListLayout")
	TreeLayout.Padding = UDim.new(0, 4)
	TreeLayout.Parent = TreeScrollFrame

	local TreePadding = Instance.new("UIPadding")
	TreePadding.PaddingLeft = UDim.new(0, Constants.SIZES.PaddingSmall)
	TreePadding.PaddingRight = UDim.new(0, Constants.SIZES.PaddingSmall)
	TreePadding.PaddingTop = UDim.new(0, Constants.SIZES.PaddingSmall)
	TreePadding.PaddingBottom = UDim.new(0, Constants.SIZES.PaddingSmall)
	TreePadding.Parent = TreeScrollFrame

	TreeLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		local MaxWidth = 300
		for _, Child in ipairs(TreeScrollFrame:GetChildren()) do
			if Child:IsA("Frame") then
				local EndX = Child.Position.X.Offset + Child.Size.X.Offset
				if EndX > MaxWidth then
					MaxWidth = EndX
				end
			end
		end
		TreeScrollFrame.CanvasSize = UDim2.fromOffset(MaxWidth + 20, TreeLayout.AbsoluteContentSize.Y + 20)
	end)

	return TreeScrollFrame
end

function TreeView.Refresh(
	TreeScrollFrame: ScrollingFrame,
	RootNode: DialogNode?,
	SelectedNode: DialogNode?,
	OnNodeSelected: (DialogNode) -> ()
)
	for _, Child in ipairs(TreeScrollFrame:GetChildren()) do
		if Child:IsA("Frame") then
			Child:Destroy()
		end
	end

	if not RootNode then return end

	RenderNode(RootNode, TreeScrollFrame, 0, "", SelectedNode, OnNodeSelected)
end

function RenderNode(
	Node: DialogNode,
	Parent: Instance,
	Depth: number,
	PathPrefix: string,
	SelectedNode: DialogNode?,
	OnNodeSelected: (DialogNode) -> ()
)
	local IsSelected = Node == SelectedNode
	local IndentAmount = Depth * 20

	local NodeFrame = Instance.new("Frame")
	NodeFrame.Size = UDim2.new(1, -IndentAmount, 0, 36)
	NodeFrame.Position = UDim2.fromOffset(IndentAmount, 0)
	NodeFrame.BackgroundColor3 = IsSelected and Constants.COLORS.SelectedBg or Constants.COLORS.Panel
	NodeFrame.BorderSizePixel = 0
	NodeFrame.LayoutOrder = 0
	NodeFrame.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	Corner.Parent = NodeFrame

	if Depth > 0 then
		local Indent = Instance.new("Frame")
		Indent.Size = UDim2.new(0, 3, 1, -8)
		Indent.Position = UDim2.fromOffset(-8, 4)
		Indent.BackgroundColor3 = Constants.COLORS.Border
		Indent.BorderSizePixel = 0
		Indent.Parent = NodeFrame

		local IndentCorner = Instance.new("UICorner")
		IndentCorner.CornerRadius = UDim.new(1, 0)
		IndentCorner.Parent = Indent
	end

	local NodeButton = Instance.new("TextButton")
	NodeButton.Size = UDim2.fromScale(1, 1)
	NodeButton.BackgroundTransparency = 1
	NodeButton.AutoButtonColor = false

	local Prefix = PathPrefix ~= "" and PathPrefix .. " " or ""
	local TruncatedText = Node.Text:sub(1, 25)
	if Node.Text:len() > 25 then
		TruncatedText = TruncatedText .. "..."
	end

	NodeButton.Text = Prefix .. TruncatedText
	NodeButton.TextColor3 = IsSelected and Constants.COLORS.TextPrimary or Constants.COLORS.TextSecondary
	NodeButton.TextXAlignment = Enum.TextXAlignment.Left
	NodeButton.Font = IsSelected and Constants.FONTS.Bold or Constants.FONTS.Medium
	NodeButton.TextSize = Constants.TEXT_SIZES.Normal
	NodeButton.Parent = NodeFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 12)
	Padding.PaddingRight = UDim.new(0, 8)
	Padding.Parent = NodeButton

	NodeButton.MouseEnter:Connect(function()
		if not IsSelected then
			TweenService:Create(NodeFrame, TWEEN_INFO, {
				BackgroundColor3 = Constants.COLORS.PanelHover
			}):Play()
			TweenService:Create(NodeButton, TWEEN_INFO, {
				TextColor3 = Constants.COLORS.TextPrimary
			}):Play()
		end
	end)

	NodeButton.MouseLeave:Connect(function()
		if not IsSelected then
			TweenService:Create(NodeFrame, TWEEN_INFO, {
				BackgroundColor3 = Constants.COLORS.Panel
			}):Play()
			TweenService:Create(NodeButton, TWEEN_INFO, {
				TextColor3 = Constants.COLORS.TextSecondary
			}):Play()
		end
	end)

	NodeButton.MouseButton1Click:Connect(function()
		OnNodeSelected(Node)
	end)

	if Node.Choices then
		for Index, Choice in ipairs(Node.Choices) do
			local Letter = string.char(96 + Index)
			local NewPath = tostring(Index) .. Letter

			if Choice.SkillCheck then
				if Choice.SkillCheck.SuccessNode then
					RenderNode(Choice.SkillCheck.SuccessNode, Parent, Depth + 1, NewPath .. "✓", SelectedNode, OnNodeSelected)
				end
				if Choice.SkillCheck.FailureNode then
					RenderNode(Choice.SkillCheck.FailureNode, Parent, Depth + 1, NewPath .. "✗", SelectedNode, OnNodeSelected)
				end
			elseif Choice.ResponseNode then
				RenderNode(Choice.ResponseNode, Parent, Depth + 1, NewPath, SelectedNode, OnNodeSelected)
			end
		end
	end
end

return TreeView