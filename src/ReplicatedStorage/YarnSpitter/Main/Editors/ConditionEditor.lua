--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local ConditionEditor = {}

function ConditionEditor.Render(
	Choice: DialogChoice,
	Container: Frame,
	StartOrder: number,
	OnRefresh: () -> ()
): number
	local CurrentOrder = StartOrder

	Components.CreateLabel("Conditions (all must be true):", Container, CurrentOrder)
	CurrentOrder += 1

	if not Choice.Conditions then
		Choice.Conditions = {}
	end

	for Index, Condition in ipairs(Choice.Conditions) do
		local ConditionContainer = Components.CreateContainer(Container, CurrentOrder)
		CurrentOrder += 1

		Components.CreateLabel("Condition " .. tostring(Index), ConditionContainer, 1)

		Components.CreateDropdown(
			Constants.CONDITION_TYPES,
			Condition.Type,
			ConditionContainer,
			2,
			function(NewType)
				Condition.Type = NewType
				Condition.Value = ""
				OnRefresh()
			end
		)

		local ValueLabel = "Value:"
		if Condition.Type == "DialogFlag" then
			ValueLabel = "Flag Name:"
		elseif Condition.Type == "HasQuest" or Condition.Type == "CompletedQuest" or Condition.Type == "CanTurnInQuest" then
			ValueLabel = "Quest ID:"
		elseif Condition.Type == "HasItem" then
			ValueLabel = "Item Name:"
		elseif Condition.Type == "Level" then
			ValueLabel = "Min Level:"
		elseif Condition.Type == "HasSkill" then
			ValueLabel = "Skill/Min Value (e.g., Perception/10):"
		elseif Condition.Type == "HasReputation" then
			ValueLabel = "Faction/Min (e.g., Police/50):"
		end

		Components.CreateLabel(ValueLabel, ConditionContainer, 3)
		Components.CreateTextBox(
			tostring(Condition.Value),
			ConditionContainer,
			4,
			false,
			function(NewValue)
				Condition.Value = NewValue
			end
		)

		Components.CreateButton(
			"Delete Condition",
			ConditionContainer,
			5,
			Constants.COLORS.Danger,
			function()
				DialogTree.RemoveCondition(Choice, Index)
				OnRefresh()
			end
		)
	end

	Components.CreateButton(
		"+ Add Condition",
		Container,
		CurrentOrder,
		Constants.COLORS.Primary,
		function()
			DialogTree.AddCondition(Choice, "DialogFlag", "")
			OnRefresh()
		end
	)
	CurrentOrder += 1

	return CurrentOrder
end

return ConditionEditor