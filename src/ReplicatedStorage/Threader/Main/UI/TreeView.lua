--!strict
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local TweenService = game:GetService("TweenService")

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local TreeView = {}
local TreeFrame: Frame

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function TreeView.Create(Parent: Frame): ScrollingFrame
	TreeFrame = Instance.new("Frame")
	TreeFrame.Name = "TreeView"
	TreeFrame.Size = UDim2.new(0.55, -10, 1, -Constants.SIZES.TopBarHeight - 10)
	TreeFrame.Position = UDim2.fromOffset(5, Constants.SIZES.TopBarHeight + 5)
	TreeFrame.BackgroundColor3 = Constants.COLORS.Panel
	TreeFrame.BorderSizePixel = 1
	TreeFrame.BorderColor3 = Constants.COLORS.Border
	TreeFrame.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = TreeFrame

	local TreeScrollFrame = Instance.new("ScrollingFrame")
	TreeScrollFrame.Name = "TreeScrollFrame"
	TreeScrollFrame.Size = UDim2.fromScale(1, 1)
	TreeScrollFrame.BackgroundTransparency = 1
	TreeScrollFrame.ScrollBarThickness = 6
	TreeScrollFrame.ScrollBarImageColor3 = Constants.COLORS.Border
	TreeScrollFrame.BorderSizePixel = 0
	TreeScrollFrame.CanvasSize = UDim2.fromOffset(0, 0)
	TreeScrollFrame.Parent = TreeFrame

	return TreeScrollFrame
end

function TreeView.UpdateSize(DividerPosition: number)
	if TreeFrame then
		TreeFrame.Size = UDim2.new(DividerPosition, -10, 1, -Constants.SIZES.TopBarHeight - 10)
	end
end

local RenderOrder = 0

local function RenderNode(
	Node: DialogNode,
	Parent: Instance,
	Depth: number,
	_: string,
	SelectedNode: DialogNode?,
	SelectedChoice: DialogChoice?,
	OnNodeSelected: (DialogNode) -> (),
	OnChoiceSelected: (DialogChoice) -> ()
)
	local IsSelected = Node == SelectedNode

	local NodeFrame = Instance.new("Frame")
	NodeFrame.Name = "Node_" .. Node.Id
	NodeFrame.Size = UDim2.new(1, -Depth * 20, 0, 32)
	NodeFrame.BackgroundColor3 = IsSelected and Constants.COLORS.SelectedBg or Constants.COLORS.Panel
	NodeFrame.BorderSizePixel = 0
	NodeFrame.LayoutOrder = RenderOrder
	RenderOrder = RenderOrder + 1
	NodeFrame.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = NodeFrame

	local Indent = Instance.new("Frame")
	Indent.Size = UDim2.fromOffset(Depth * 20, 32)
	Indent.BackgroundTransparency = 1
	Indent.Parent = NodeFrame

	local NodeButton = Instance.new("TextButton")
	NodeButton.Size = UDim2.new(1, -Depth * 20, 1, 0)
	NodeButton.Position = UDim2.fromOffset(Depth * 20, 0)
	NodeButton.BackgroundTransparency = 1
	NodeButton.Text = Node.Id .. " - " .. Node.Text:sub(1, 30) .. (Node.Text:len() > 30 and "..." or "")
	NodeButton.TextXAlignment = Enum.TextXAlignment.Left
	NodeButton.TextColor3 = IsSelected and Constants.COLORS.Primary or Constants.COLORS.TextSecondary
	NodeButton.Font = IsSelected and Constants.FONTS.Bold or Constants.FONTS.Regular
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
			local IsChoiceSelected = Choice == SelectedChoice

			local ChoiceFrame = Instance.new("Frame")
			ChoiceFrame.Name = "Choice_" .. tostring(Index)
			ChoiceFrame.Size = UDim2.new(1, -(Depth + 1) * 20, 0, 28)
			ChoiceFrame.BackgroundColor3 = IsChoiceSelected and Constants.COLORS.SelectedBg or Constants.COLORS.BackgroundDark
			ChoiceFrame.BorderSizePixel = 0
			ChoiceFrame.LayoutOrder = RenderOrder
			RenderOrder = RenderOrder + 1
			ChoiceFrame.Parent = Parent

			local ChoiceCorner = Instance.new("UICorner")
			ChoiceCorner.CornerRadius = UDim.new(0, 4)
			ChoiceCorner.Parent = ChoiceFrame

			local ChoiceIndent = Instance.new("Frame")
			ChoiceIndent.Size = UDim2.fromOffset((Depth + 1) * 20, 28)
			ChoiceIndent.BackgroundTransparency = 1
			ChoiceIndent.Parent = ChoiceFrame

			local ChoiceButton = Instance.new("TextButton")
			ChoiceButton.Size = UDim2.new(1, -(Depth + 1) * 20, 1, 0)
			ChoiceButton.Position = UDim2.fromOffset((Depth + 1) * 20, 0)
			ChoiceButton.BackgroundTransparency = 1
			ChoiceButton.Text = "→ " .. (Choice.Id or "choice_unknown") .. " - " .. Choice.ButtonText:sub(1, 20) .. (Choice.ButtonText:len() > 20 and "..." or "")
			ChoiceButton.TextXAlignment = Enum.TextXAlignment.Left
			ChoiceButton.TextColor3 = IsChoiceSelected and Constants.COLORS.Primary or Constants.COLORS.Accent
			ChoiceButton.Font = IsChoiceSelected and Constants.FONTS.Bold or Constants.FONTS.Regular
			ChoiceButton.TextSize = Constants.TEXT_SIZES.Small
			ChoiceButton.Parent = ChoiceFrame

			local ChoicePadding = Instance.new("UIPadding")
			ChoicePadding.PaddingLeft = UDim.new(0, 12)
			ChoicePadding.PaddingRight = UDim.new(0, 8)
			ChoicePadding.Parent = ChoiceButton

			ChoiceButton.MouseEnter:Connect(function()
				if not IsChoiceSelected then
					TweenService:Create(ChoiceFrame, TWEEN_INFO, {
						BackgroundColor3 = Constants.COLORS.PanelHover
					}):Play()
					TweenService:Create(ChoiceButton, TWEEN_INFO, {
						TextColor3 = Constants.COLORS.TextPrimary
					}):Play()
				end
			end)

			ChoiceButton.MouseLeave:Connect(function()
				if not IsChoiceSelected then
					TweenService:Create(ChoiceFrame, TWEEN_INFO, {
						BackgroundColor3 = Constants.COLORS.BackgroundDark
					}):Play()
					TweenService:Create(ChoiceButton, TWEEN_INFO, {
						TextColor3 = Constants.COLORS.Accent
					}):Play()
				end
			end)

			ChoiceButton.MouseButton1Click:Connect(function()
				OnChoiceSelected(Choice)
			end)

			if Choice.SkillCheck then
				if Choice.SkillCheck.SuccessNode then
					RenderNode(Choice.SkillCheck.SuccessNode, Parent, Depth + 2, "", SelectedNode, SelectedChoice, OnNodeSelected, OnChoiceSelected)
				end
				if Choice.SkillCheck.FailureNode then
					RenderNode(Choice.SkillCheck.FailureNode, Parent, Depth + 2, "", SelectedNode, SelectedChoice, OnNodeSelected, OnChoiceSelected)
				end
			elseif Choice.ResponseNode then
				RenderNode(Choice.ResponseNode, Parent, Depth + 2, "", SelectedNode, SelectedChoice, OnNodeSelected, OnChoiceSelected)
			end
		end
	end
end

function TreeView.Refresh(
	TreeScrollFrameParam: ScrollingFrame,
	RootNode: DialogNode?,
	SelectedNode: DialogNode?,
	SelectedChoice: DialogChoice?,
	OnNodeSelected: (DialogNode) -> (),
	OnChoiceSelected: (DialogChoice) -> ()
)
	for _, Child in ipairs(TreeScrollFrameParam:GetChildren()) do
		if Child:IsA("Frame") then
			Child:Destroy()
		end
	end

	if not RootNode then
		return
	end

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 4)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = TreeScrollFrameParam

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TreeScrollFrameParam.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 8)
	end)

	RenderOrder = 0
	RenderNode(RootNode, TreeScrollFrameParam, 0, "", SelectedNode, SelectedChoice, OnNodeSelected, OnChoiceSelected)
end

return TreeView