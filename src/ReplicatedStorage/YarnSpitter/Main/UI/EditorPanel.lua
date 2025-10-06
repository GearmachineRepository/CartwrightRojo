--!strict
local Constants = require(script.Parent.Parent.Constants)
local Components = require(script.Parent.Components)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local SimpleChoiceEditor = require(script.Parent.Parent.Editors.SimpleChoiceEditor)
local SkillCheckEditor = require(script.Parent.Parent.Editors.SkillCheckEditor)
local ConditionEditor = require(script.Parent.Parent.Editors.ConditionEditor)
local CommandEditor = require(script.Parent.Parent.Editors.CommandEditor)
local FlagsEditor = require(script.Parent.Parent.Editors.FlagsEditor)
local QuestTurnInEditor = require(script.Parent.Parent.Editors.QuestTurnInEditor)

type DialogNode = DialogTree.DialogNode

local EditorPanel = {}

local EditorFrame: Frame

function EditorPanel.Create(Parent: Instance): ScrollingFrame
	EditorFrame = Instance.new("Frame")
	EditorFrame.Size = UDim2.new(Constants.SIZES.EditorWidth, -10, 1, -Constants.SIZES.TopBarHeight - 10)
	EditorFrame.Position = UDim2.new(Constants.SIZES.TreeViewWidth, 5, 0, Constants.SIZES.TopBarHeight + 5)
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
		EditorScroll.CanvasSize = UDim2.fromOffset(0, EditorLayout.AbsoluteContentSize.Y + Constants.SIZES.Padding * 2)
	end)

	return EditorScroll
end

function EditorPanel.UpdateSize(DividerPosition: number)
	if EditorFrame then
		EditorFrame.Size = UDim2.new(1 - DividerPosition, -10, 1, -Constants.SIZES.TopBarHeight - 10)
		EditorFrame.Position = UDim2.new(DividerPosition, 5, 0, Constants.SIZES.TopBarHeight + 5)
	end
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

	Components.CreateLabel("Default Dialog Text:", EditorScroll, 1)
	Components.CreateTextBox(SelectedNode.Text, EditorScroll, 2, true, function(NewText: string)
		SelectedNode.Text = NewText
		OnRefresh()
	end)

	local _, GreetingsContent = Components.CreateCollapsibleSection(
		"Conditional Greetings",
		EditorScroll,
		3,
		true
	)

	if not SelectedNode.Greetings then
		SelectedNode.Greetings = {}
	end

	for Index, Greeting in ipairs(SelectedNode.Greetings) do
		local GreetingContainer = Components.CreateContainer(GreetingsContent, Index)

		Components.CreateLabel("Condition Type:", GreetingContainer, 1)
		Components.CreateDropdown(
			{"HasQuest", "CompletedQuest", "DialogFlag"},
			Greeting.ConditionType,
			GreetingContainer,
			2,
			function(NewType: string)
				Greeting.ConditionType = NewType
				OnRefresh()
			end
		)

		Components.CreateLabel("Condition Value:", GreetingContainer, 3)
		Components.CreateTextBox(Greeting.ConditionValue, GreetingContainer, 4, false, function(NewValue: string)
			Greeting.ConditionValue = NewValue
		end)

		Components.CreateLabel("Greeting Text:", GreetingContainer, 5)
		Components.CreateTextBox(Greeting.GreetingText, GreetingContainer, 6, true, function(NewText: string)
			Greeting.GreetingText = NewText
		end)

		Components.CreateButton("Delete Greeting", GreetingContainer, 100, Constants.COLORS.Danger, function()
			DialogTree.RemoveGreeting(SelectedNode, Index)
			OnRefresh()
		end)
	end

	Components.CreateButton("+ Add Greeting", GreetingsContent, 1000, Constants.COLORS.Accent, function()
		DialogTree.AddGreeting(SelectedNode, "HasQuest", "QuestID", "Greeting text...")
		OnRefresh()
	end)

	Components.CreateLabel("Choices:", EditorScroll, 4)

	if not SelectedNode.Choices then
		SelectedNode.Choices = {}
	end

	for Index, Choice in ipairs(SelectedNode.Choices) do
		local BaseOrder = 4 + Index * 100

		local _, ChoiceContent = Components.CreateCollapsibleSection(
			"Choice " .. tostring(Index) .. ": " .. Choice.ButtonText:sub(1, 30),
			EditorScroll,
			BaseOrder,
			false
		)

		local _, ConditionsContent = Components.CreateCollapsibleSection(
			"Conditions",
			ChoiceContent,
			1,
			true
		)
		ConditionEditor.Render(Choice, ConditionsContent, 1, OnRefresh)

		Components.CreateToggleButton(
			"Skill Check",
			Choice.SkillCheck ~= nil,
			ChoiceContent,
			2,
			function(IsToggled: boolean)
				if IsToggled then
					DialogTree.ConvertToSkillCheck(Choice, "Perception", 10)
				else
					DialogTree.ConvertToSimpleChoice(Choice)
				end
				OnRefresh()
			end
		)

		Components.CreateToggleButton(
			"Quest Turn-In",
			Choice.QuestTurnIn ~= nil,
			ChoiceContent,
			2.5,
			function(IsToggled: boolean)
				if IsToggled then
					DialogTree.ConvertToQuestTurnIn(Choice, "QuestID")
				else
					DialogTree.ConvertToSimpleChoice(Choice)
				end
				OnRefresh()
			end
		)

		if Choice.QuestTurnIn then
			QuestTurnInEditor.Render(
				Choice,
				Index,
				ChoiceContent,
				3,
				function()
					DialogTree.RemoveChoice(SelectedNode, Index)
					OnRefresh()
				end
			)
		elseif Choice.SkillCheck then
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

		local _, FlagsContent = Components.CreateCollapsibleSection(
			"Flags",
			ChoiceContent,
			4,
			true
		)
		FlagsEditor.Render(Choice, FlagsContent, 1, OnRefresh)

		local _, CommandContent = Components.CreateCollapsibleSection(
			"Commands",
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