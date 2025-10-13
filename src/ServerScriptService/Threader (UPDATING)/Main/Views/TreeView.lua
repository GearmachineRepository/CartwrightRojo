--!strict
local Colors = require(script.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Theme.Spacing)
local UIStateManager = require(script.Parent.Parent.Managers.UIStateManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)
local ZIndexManager = require(script.Parent.Parent.Managers.ZIndexManager)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local TreeView = {}

local Connections = ConnectionManager.Create()

function TreeView.Create(Parent: Frame): ScrollingFrame
	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Size = UDim2.new(0, 250, 1, -30)
	ScrollFrame.Position = UDim2.fromOffset(0, 30)
	ScrollFrame.BackgroundColor3 = Colors.BackgroundDark
	ScrollFrame.BorderSizePixel = 0
	ScrollFrame.ScrollBarThickness = 6
	ScrollFrame.ScrollBarImageColor3 = Colors.Border
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollFrame.Parent = Parent

	ZIndexManager.SetLayer(ScrollFrame, "UI")

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Small)
	Layout.Parent = ScrollFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.Padding)
	Padding.PaddingRight = UDim.new(0, Spacing.Padding)
	Padding.PaddingTop = UDim.new(0, Spacing.Padding)
	Padding.PaddingBottom = UDim.new(0, Spacing.Padding)
	Padding.Parent = ScrollFrame

	Connections:Add(Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollFrame.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + Spacing.Padding * 2)
	end))

	return ScrollFrame
end

function TreeView.Refresh(ScrollFrame: ScrollingFrame, Tree: DialogNode?, OnNodeSelected: (DialogNode) -> (), OnChoiceSelected: (DialogChoice) -> ())
	Connections:Cleanup()
	Connections = ConnectionManager.Create()

	ScrollFrame:ClearAllChildren()

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Small)
	Layout.Parent = ScrollFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.Padding)
	Padding.PaddingRight = UDim.new(0, Spacing.Padding)
	Padding.PaddingTop = UDim.new(0, Spacing.Padding)
	Padding.PaddingBottom = UDim.new(0, Spacing.Padding)
	Padding.Parent = ScrollFrame

	Connections:Add(Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollFrame.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + Spacing.Padding * 2)
	end))

	if not Tree then
		local NoDataLabel = Instance.new("TextLabel")
		NoDataLabel.Size = UDim2.new(1, 0, 0, 40)
		NoDataLabel.BackgroundTransparency = 1
		NoDataLabel.Text = "No dialog tree loaded"
		NoDataLabel.TextColor3 = Colors.TextSecondary
		NoDataLabel.Font = Fonts.Regular
		NoDataLabel.TextSize = 14
		NoDataLabel.Parent = ScrollFrame
		return
	end

	local LayoutOrder = 0

	local function RenderNode(Node: DialogNode, Depth: number)
		LayoutOrder = LayoutOrder + 1

		local NodeButton = Instance.new("TextButton")
		NodeButton.Size = UDim2.new(1, -Depth * 20, 0, 32)
		NodeButton.Position = UDim2.fromOffset(Depth * 20, 0)
		NodeButton.BackgroundColor3 = Colors.BackgroundLight
		NodeButton.BorderSizePixel = 0
		NodeButton.Text = "  " .. (Node.Text:sub(1, 30) .. (Node.Text:len() > 30 and "..." or ""))
		NodeButton.TextColor3 = Colors.Text
		NodeButton.Font = Fonts.Regular
		NodeButton.TextSize = 13
		NodeButton.TextXAlignment = Enum.TextXAlignment.Left
		NodeButton.LayoutOrder = LayoutOrder
		NodeButton.Parent = ScrollFrame

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 4)
		Corner.Parent = NodeButton

		local SelectedNode = UIStateManager.GetSelectedNode()
		if SelectedNode == Node then
			NodeButton.BackgroundColor3 = Colors.Primary
		end

		Connections:Add(NodeButton.MouseButton1Click:Connect(function()
			UIStateManager.SelectNode(Node)
			OnNodeSelected(Node)
		end))

		Connections:Add(NodeButton.MouseEnter:Connect(function()
			if UIStateManager.GetSelectedNode() ~= Node then
				NodeButton.BackgroundColor3 = Colors.Border
			end
		end))

		Connections:Add(NodeButton.MouseLeave:Connect(function()
			if UIStateManager.GetSelectedNode() ~= Node then
				NodeButton.BackgroundColor3 = Colors.BackgroundLight
			end
		end))

		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				LayoutOrder = LayoutOrder + 1

				local ChoiceButton = Instance.new("TextButton")
				ChoiceButton.Size = UDim2.new(1, -(Depth + 1) * 20, 0, 28)
				ChoiceButton.Position = UDim2.fromOffset((Depth + 1) * 20, 0)
				ChoiceButton.BackgroundColor3 = Colors.Background
				ChoiceButton.BorderSizePixel = 0
				ChoiceButton.Text = "  → " .. (Choice.Text:sub(1, 25) .. (Choice.Text:len() > 25 and "..." or ""))
				ChoiceButton.TextColor3 = Colors.TextSecondary
				ChoiceButton.Font = Fonts.Regular
				ChoiceButton.TextSize = 12
				ChoiceButton.TextXAlignment = Enum.TextXAlignment.Left
				ChoiceButton.LayoutOrder = LayoutOrder
				ChoiceButton.Parent = ScrollFrame

				local ChoiceCorner = Instance.new("UICorner")
				ChoiceCorner.CornerRadius = UDim.new(0, 4)
				ChoiceCorner.Parent = ChoiceButton

				local SelectedChoice = UIStateManager.GetSelectedChoice()
				if SelectedChoice == Choice then
					ChoiceButton.BackgroundColor3 = Colors.Primary
				end

				Connections:Add(ChoiceButton.MouseButton1Click:Connect(function()
					UIStateManager.SelectChoice(Choice)
					OnChoiceSelected(Choice)
				end))

				Connections:Add(ChoiceButton.MouseEnter:Connect(function()
					if UIStateManager.GetSelectedChoice() ~= Choice then
						ChoiceButton.BackgroundColor3 = Colors.BackgroundDark
					end
				end))

				Connections:Add(ChoiceButton.MouseLeave:Connect(function()
					if UIStateManager.GetSelectedChoice() ~= Choice then
						ChoiceButton.BackgroundColor3 = Colors.Background
					end
				end))

				if Choice.ResponseNode then
					RenderNode(Choice.ResponseNode, Depth + 2)
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						RenderNode(Choice.SkillCheck.SuccessNode, Depth + 2)
					end
					if Choice.SkillCheck.FailureNode then
						RenderNode(Choice.SkillCheck.FailureNode, Depth + 2)
					end
				end
			end
		end

		if Node.NextResponseNode then
			RenderNode(Node.NextResponseNode, Depth)
		end
	end

	RenderNode(Tree, 0)
end

function TreeView.UpdateSize(NewWidth: number)
end

function TreeView.Cleanup()
	Connections:Cleanup()
end

return TreeView