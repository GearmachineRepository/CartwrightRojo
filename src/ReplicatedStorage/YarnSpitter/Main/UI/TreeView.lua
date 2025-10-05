--!strict
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local TreeView = {}

function TreeView.Create(Parent: Instance): ScrollingFrame
	local TreeScrollFrame = Instance.new("ScrollingFrame")
	TreeScrollFrame.Size = UDim2.new(Constants.SIZES.TreeViewWidth, -5, 1, -45)
	TreeScrollFrame.Position = UDim2.new(0, 5, 0, 45)
	TreeScrollFrame.BackgroundColor3 = Constants.COLORS.Panel
	TreeScrollFrame.BorderSizePixel = 0
	TreeScrollFrame.ScrollBarThickness = Constants.SIZES.ScrollBarThickness
	TreeScrollFrame.Parent = Parent

	local TreeLayout = Instance.new("UIListLayout")
	TreeLayout.Padding = UDim.new(0, 2)
	TreeLayout.Parent = TreeScrollFrame

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

	RenderNode(RootNode, TreeScrollFrame, 0, nil, SelectedNode, OnNodeSelected)
end

function RenderNode(
	Node: DialogNode,
	Parent: Instance,
	Depth: number,
	ChoiceNumber: number?,
	SelectedNode: DialogNode?,
	OnNodeSelected: (DialogNode) -> ()
)
	local NodeFrame = Instance.new("Frame")
	NodeFrame.Size = UDim2.new(1, -Depth * 20, 0, 30)
	NodeFrame.BackgroundColor3 = Node == SelectedNode and Constants.COLORS.Selected or Constants.COLORS.Unselected
	NodeFrame.BorderSizePixel = 0
	NodeFrame.Parent = Parent

	local NodeButton = Instance.new("TextButton")
	NodeButton.Size = UDim2.fromScale(1, 1)
	NodeButton.BackgroundTransparency = 1
	local Prefix = ChoiceNumber and "[" .. tostring(ChoiceNumber) .. "] " or ""
	NodeButton.Text = Prefix .. Node.Text:sub(1, 30) .. (Node.Text:len() > 30 and "..." or "")
	NodeButton.TextColor3 = Constants.COLORS.TextPrimary
	NodeButton.TextXAlignment = Enum.TextXAlignment.Left
	NodeButton.Font = Constants.FONTS.Medium
	NodeButton.TextSize = Constants.TEXT_SIZES.Medium
	NodeButton.Parent = NodeFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 5 + Depth * 20)
	Padding.Parent = NodeButton

	NodeButton.MouseButton1Click:Connect(function()
		OnNodeSelected(Node)
	end)

	if Node.Choices then
		for Index, Choice in ipairs(Node.Choices) do
			if Choice.SkillCheck then
				if Choice.SkillCheck.SuccessNode then
					RenderNode(Choice.SkillCheck.SuccessNode, Parent, Depth + 1, Index, SelectedNode, OnNodeSelected)
				end
				if Choice.SkillCheck.FailureNode then
					RenderNode(Choice.SkillCheck.FailureNode, Parent, Depth + 1, Index, SelectedNode, OnNodeSelected)
				end
			elseif Choice.ResponseNode then
				RenderNode(Choice.ResponseNode, Parent, Depth + 1, Index, SelectedNode, OnNodeSelected)
			end
		end
	end
end

return TreeView