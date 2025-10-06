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

	if not Choice.Conditions then
		Choice.Conditions = {}
	end

	for Index, Condition in ipairs(Choice.Conditions) do
		local ConditionContainer = Components.CreateContainer(Container, CurrentOrder)
		CurrentOrder += 1

		Components.CreateLabel("Condition " .. tostring(Index), ConditionContainer, 1)

		Components.CreateLabel("Type:", ConditionContainer, 2)
		Components.CreateDropdown(
			Constants.CONDITION_TYPES,
			Condition.Type or "DialogFlag",
			ConditionContainer,
			3,
			function(NewType: string)
				Condition.Type = NewType
				Condition.Value = ""
				OnRefresh()
			end
		)

		local ValueLabel = "Value:"
		if Condition.Type == "DialogFlag" then
			ValueLabel = "Flag:"
		elseif Condition.Type == "HasQuest" or Condition.Type == "CompletedQuest" or Condition.Type == "CanTurnInQuest" then
			ValueLabel = "Quest ID:"
		elseif Condition.Type == "HasItem" then
			ValueLabel = "Item:"
		elseif Condition.Type == "Level" then
			ValueLabel = "Min Level:"
		elseif Condition.Type == "HasSkill" then
			ValueLabel = "Skill/Val:"
		elseif Condition.Type == "HasReputation" then
			ValueLabel = "Faction/Val:"
		end

		Components.CreateLabel(ValueLabel, ConditionContainer, 4)
		Components.CreateTextBox(tostring(Condition.Value or ""), ConditionContainer, 5, false, function(NewValue: string)
			Condition.Value = NewValue
		end)

		Components.CreateButton("Delete Condition", ConditionContainer, 100, Constants.COLORS.Danger, function()
			DialogTree.RemoveCondition(Choice, Index)
			task.wait()
			OnRefresh()
		end)
	end

	Components.CreateButton(
		"+ Add Condition",
		Container,
		CurrentOrder,
		Constants.COLORS.Primary,
		function()
			DialogTree.AddCondition(Choice, "DialogFlag", "")
			task.wait()
			OnRefresh()
		end
	)
	CurrentOrder += 1

	return CurrentOrder
end

return ConditionEditor