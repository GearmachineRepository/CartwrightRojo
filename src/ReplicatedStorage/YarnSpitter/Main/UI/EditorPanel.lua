--!strict
local Constants = require(script.Parent.Parent.Constants)
local Components = require(script.Parent.Components)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local SimpleChoiceEditor = require(script.Parent.Parent.Editors.SimpleChoiceEditor)
local SkillCheckEditor = require(script.Parent.Parent.Editors.SkillCheckEditor)
local ConditionEditor = require(script.Parent.Parent.Editors.ConditionEditor)
local CommandEditor = require(script.Parent.Parent.Editors.CommandEditor)
local FlagsEditor = require(script.Parent.Parent.Editors.FlagsEditor)

type DialogNode = DialogTree.DialogNode

local EditorPanel = {}

function EditorPanel.Create(Parent: Instance): ScrollingFrame
	local EditorFrame = Instance.new("Frame")
	EditorFrame.Size = UDim2.new(Constants.SIZES.EditorWidth, -10, 1, -45)
	EditorFrame.Position = UDim2.new(Constants.SIZES.TreeViewWidth, 5, 0, 45)
	EditorFrame.BackgroundColor3 = Constants.COLORS.BackgroundLight
	EditorFrame.BorderSizePixel = 0
	EditorFrame.Parent = Parent

	local EditorScroll = Instance.new("ScrollingFrame")
	EditorScroll.Size = UDim2.fromScale(1, 1)
	EditorScroll.BackgroundTransparency = 1
	EditorScroll.ScrollBarThickness = Constants.SIZES.ScrollBarThickness
	EditorScroll.Parent = EditorFrame

	local EditorLayout = Instance.new("UIListLayout")
	EditorLayout.Padding = UDim.new(0, Constants.SIZES.Padding)
	EditorLayout.SortOrder = Enum.SortOrder.LayoutOrder
	EditorLayout.Parent = EditorScroll

	local EditorPadding = Instance.new("UIPadding")
	EditorPadding.PaddingLeft = UDim.new(0, Constants.SIZES.Padding)
	EditorPadding.PaddingRight = UDim.new(0, Constants.SIZES.Padding)
	EditorPadding.PaddingTop = UDim.new(0, Constants.SIZES.Padding)
	EditorPadding.Parent = EditorScroll

	EditorLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		EditorScroll.CanvasSize = UDim2.new(0, 0, 0, EditorLayout.AbsoluteContentSize.Y + Constants.SIZES.Padding * 2)
	end)

	return EditorScroll
end

function EditorPanel.Refresh(
	EditorScroll: ScrollingFrame,
	SelectedNode: DialogNode?,
	OnRefresh: () -> (),
	OnNavigate: (DialogNode) -> ()
)
	for _, Child in ipairs(EditorScroll:GetChildren()) do
		if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
			Child:Destroy()
		end
	end

	if not SelectedNode then
		local Label = Instance.new("TextLabel")
		Label.Size = UDim2.new(1, 0, 0, 40)
		Label.Text = "Select a node to edit"
		Label.TextColor3 = Constants.COLORS.TextMuted
		Label.BackgroundTransparency = 1
		Label.Font = Constants.FONTS.Medium
		Label.TextSize = Constants.TEXT_SIZES.Large
		Label.Parent = EditorScroll
		return
	end

	Components.CreateLabel("Dialog Text:", EditorScroll, 1)
	Components.CreateTextBox(SelectedNode.Text, EditorScroll, 2, true, function(NewText)
		SelectedNode.Text = NewText
		OnRefresh()
	end)

	Components.CreateLabel("Choices:", EditorScroll, 3)

	if not SelectedNode.Choices then
		SelectedNode.Choices = {}
	end

	for Index, Choice in ipairs(SelectedNode.Choices) do
		local BaseOrder = 3 + Index * 100

		local ChoiceSection, ChoiceContent = Components.CreateCollapsibleSection(
			"Choice " .. tostring(Index) .. ": " .. Choice.ButtonText:sub(1, 30),
			EditorScroll,
			BaseOrder,
			false
		)

		-- Conditions
		local ConditionsSection, ConditionsContent = Components.CreateCollapsibleSection(
			"🔒 Conditions",
			ChoiceContent,
			1,
			true
		)
		ConditionEditor.Render(Choice, ConditionsContent, 1, OnRefresh)

		-- Skill Check Toggle
		Components.CreateToggleButton(
			"Skill Check",
			Choice.SkillCheck ~= nil,
			ChoiceContent,
			2,
			function(IsToggled)
				if IsToggled then
					DialogTree.ConvertToSkillCheck(Choice, "Perception", 10)
				else
					DialogTree.ConvertToSimpleChoice(Choice)
				end
				OnRefresh()
			end
		)

		-- Choice Editor
		if Choice.SkillCheck then
			SkillCheckEditor.Render(
				Choice,
				Index,
				ChoiceContent,
				3,
				function()
					DialogTree.RemoveChoice(SelectedNode, Index)
					OnRefresh()
				end,
				OnNavigate
			)
		else
			SimpleChoiceEditor.Render(
				Choice,
				Index,
				ChoiceContent,
				3,
				function()
					DialogTree.RemoveChoice(SelectedNode, Index)
					OnRefresh()
				end,
				OnNavigate
			)
		end

		-- Flags
		local FlagsSection, FlagsContent = Components.CreateCollapsibleSection(
			"🏁 Flags",
			ChoiceContent,
			4,
			true
		)
		FlagsEditor.Render(Choice, FlagsContent, 1, OnRefresh)

		-- Commands
		local CommandSection, CommandContent = Components.CreateCollapsibleSection(
			"⚡ Commands",
			ChoiceContent,
			5,
			true
		)
		CommandEditor.Render(Choice, CommandContent, 1)
	end

	Components.CreateButton("+ Add Choice", EditorScroll, 1000, Constants.COLORS.Primary, function()
		DialogTree.AddChoice(SelectedNode, DialogTree.CreateChoice("New choice"))
		OnRefresh()
	end)
end

return EditorPanel