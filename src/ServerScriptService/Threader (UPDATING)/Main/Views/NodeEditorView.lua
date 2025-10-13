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

local NodeEditorView = {}

local Connections = ConnectionManager.Create()

function NodeEditorView.Create(Parent: Frame): ScrollingFrame
	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Size = UDim2.new(1, -250, 1, -30)
	ScrollFrame.Position = UDim2.new(0, 250, 0, 30)
	ScrollFrame.BackgroundColor3 = Colors.Background
	ScrollFrame.BorderSizePixel = 0
	ScrollFrame.ScrollBarThickness = 6
	ScrollFrame.ScrollBarImageColor3 = Colors.Border
	ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollFrame.Parent = Parent

	ZIndexManager.SetLayer(ScrollFrame, "UI")

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.SectionGap)
	Layout.Parent = ScrollFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.PanelPadding)
	Padding.PaddingRight = UDim.new(0, Spacing.PanelPadding)
	Padding.PaddingTop = UDim.new(0, Spacing.PanelPadding)
	Padding.PaddingBottom = UDim.new(0, Spacing.PanelPadding)
	Padding.Parent = ScrollFrame

	Connections:Add(Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + Spacing.PanelPadding * 2)
	end))

	return ScrollFrame
end

function NodeEditorView.Refresh(ScrollFrame: ScrollingFrame, OnRefresh: () -> ())
	Connections:Cleanup()
	Connections = ConnectionManager.Create()

	ScrollFrame:ClearAllChildren()

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.SectionGap)
	Layout.Parent = ScrollFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.PanelPadding)
	Padding.PaddingRight = UDim.new(0, Spacing.PanelPadding)
	Padding.PaddingTop = UDim.new(0, Spacing.PanelPadding)
	Padding.PaddingBottom = UDim.new(0, Spacing.PanelPadding)
	Padding.Parent = ScrollFrame

	Connections:Add(Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + Spacing.PanelPadding * 2)
	end))

	local SelectedNode = UIStateManager.GetSelectedNode()
	local SelectedChoice = UIStateManager.GetSelectedChoice()

	if not SelectedNode and not SelectedChoice then
		local NoSelectionLabel = Instance.new("TextLabel")
		NoSelectionLabel.Size = UDim2.new(1, 0, 0, 60)
		NoSelectionLabel.BackgroundTransparency = 1
		NoSelectionLabel.Text = "Select a node or choice to edit"
		NoSelectionLabel.TextColor3 = Colors.TextSecondary
		NoSelectionLabel.Font = Fonts.Regular
		NoSelectionLabel.TextSize = 16
		NoSelectionLabel.Parent = ScrollFrame
		return
	end

	if SelectedNode then
		local ChoiceEditor = require(script.Parent.Parent.Editors.ChoiceEditor)
		ChoiceEditor.Render(ScrollFrame, SelectedNode, OnRefresh)
	elseif SelectedChoice then
		local SkillCheckEditor = require(script.Parent.Parent.Editors.SkillCheckEditor)
		local ConditionalEditor = require(script.Parent.Parent.Editors.ConditionalEditor)

		if SelectedChoice.SkillCheck then
			SkillCheckEditor.Render(ScrollFrame, SelectedChoice, OnRefresh)
		elseif SelectedChoice.Conditions then
			ConditionalEditor.Render(ScrollFrame, SelectedChoice, OnRefresh)
		else
			local ChoiceEditor = require(script.Parent.Parent.Editors.ChoiceEditor)
			ChoiceEditor.RenderChoice(ScrollFrame, SelectedChoice, OnRefresh)
		end
	end
end

function NodeEditorView.UpdateSize(NewWidth: number)
end

function NodeEditorView.Cleanup()
	Connections:Cleanup()
end

return NodeEditorView