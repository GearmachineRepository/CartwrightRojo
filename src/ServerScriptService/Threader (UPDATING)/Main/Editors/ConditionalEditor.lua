--!strict
local NodeEditor = require(script.Parent.NodeEditor)
local Builder = require(script.Parent.Parent.Components.Builder)
local FlagsManagerWindow = require(script.Parent.Parent.Windows.FlagsManagerWindow)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local ConditionalEditor = {}

function ConditionalEditor.Render(Parent: ScrollingFrame, Choice: DialogChoice, OnRefresh: () -> ())
	local Base = NodeEditor.CreateBase(Parent, "Conditional Editor")

	if not Choice.Conditions then
		Choice.Conditions = {}
	end

	local BasicSection = NodeEditor.CreateSection(Base.Container, "Choice Properties", 1)

	Builder.LabeledInput("Choice Text:", {
		Value = Choice.Text,
		PlaceholderText = "Enter choice text...",
		OnChanged = function(Text)
			Choice.Text = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.Spacer(12).Parent = Base.Container

	local ConditionsSection, ConditionsContent = NodeEditor.CreateCollapsibleSection(
		Base.Container,
		"Conditions (" .. #Choice.Conditions .. ")",
		false
	)
	ConditionsSection.LayoutOrder = 2

	for Index, Condition in ipairs(Choice.Conditions) do
		ConditionalEditor.RenderCondition(ConditionsContent, Condition, Index, Choice, OnRefresh)
	end

	Builder.Spacer(8).Parent = ConditionsContent

	local AddConditionButton = Builder.Button({
		Text = "+ Add Condition",
		Type = "Success",
		OnClick = function()
			table.insert(Choice.Conditions, {
				Type = "HasFlag",
				Value = "None"
			})
			OnRefresh()
		end
	})
	AddConditionButton.Size = UDim2.new(0, 150, 0, 32)
	AddConditionButton.Parent = ConditionsContent
end

function ConditionalEditor.RenderCondition(Parent: Frame, Condition: any, Index: number, Choice: DialogChoice, OnRefresh: () -> ())
	local ConditionSection = NodeEditor.CreateSection(Parent, nil, Index)

	local HeaderRow = Instance.new("Frame")
	HeaderRow.Size = UDim2.new(1, 0, 0, 32)
	HeaderRow.BackgroundTransparency = 1
	HeaderRow.LayoutOrder = 0
	HeaderRow.Parent = ConditionSection

	local HeaderLayout = Instance.new("UIListLayout")
	HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderLayout.Padding = UDim.new(0, 8)
	HeaderLayout.Parent = HeaderRow

	local ConditionLabel = Builder.Label("Condition " .. Index, {Bold = true})
	ConditionLabel.Size = UDim2.new(1, -80, 1, 0)
	ConditionLabel.Parent = HeaderRow

	local DeleteButton = Builder.Button({
		Text = "Delete",
		Type = "Danger",
		OnClick = function()
			table.remove(Choice.Conditions, Index)
			OnRefresh()
		end
	})
	DeleteButton.Size = UDim2.new(0, 70, 0, 28)
	DeleteButton.Parent = HeaderRow

	Builder.Spacer(4).Parent = ConditionSection

	Builder.Dropdown({
		Label = "Condition Type:",
		Options = {"HasFlag", "MissingFlag", "LevelGreaterThan", "LevelLessThan", "HasItem", "QuestComplete"},
		Selected = Condition.Type or "HasFlag",
		OnSelected = function(Type)
			Condition.Type = Type
			OnRefresh()
		end
	}).Parent = ConditionSection

	if Condition.Type == "HasFlag" or Condition.Type == "MissingFlag" then
		local Flags = FlagsManagerWindow.GetFlags()
		Builder.Dropdown({
			Label = "Flag:",
			Options = Flags,
			Selected = Condition.Value or "None",
			OnSelected = function(Flag)
				Condition.Value = Flag
				OnRefresh()
			end
		}).Parent = ConditionSection

	elseif Condition.Type == "LevelGreaterThan" or Condition.Type == "LevelLessThan" then
		Builder.NumberInput({
			Label = "Level:",
			Value = tonumber(Condition.Value) or 1,
			Min = 1,
			Max = 100,
			OnChanged = function(Value)
				Condition.Value = Value
				OnRefresh()
			end
		}).Parent = ConditionSection

	elseif Condition.Type == "HasItem" then
		Builder.LabeledInput("Item Name:", {
			Value = tostring(Condition.Value or ""),
			PlaceholderText = "Enter item name...",
			OnChanged = function(Text)
				Condition.Value = Text
				OnRefresh()
			end
		}).Parent = ConditionSection

	elseif Condition.Type == "QuestComplete" then
		Builder.LabeledInput("Quest ID:", {
			Value = tostring(Condition.Value or ""),
			PlaceholderText = "Enter quest ID...",
			OnChanged = function(Text)
				Condition.Value = Text
				OnRefresh()
			end
		}).Parent = ConditionSection
	end
end

return ConditionalEditor