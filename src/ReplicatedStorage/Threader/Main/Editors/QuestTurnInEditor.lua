--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local QuestTurnInEditor = {}

function QuestTurnInEditor.Render(
	Choice: DialogChoice,
	_: number,
	Parent: Instance,
	Order: number,
	OnDelete: () -> ()
): Frame
	local Container = Components.CreateContainer(Parent, Order)

	Components.CreateLabeledInput("Button Text:", Choice.ButtonText, Container, 1, function(NewText)
		Choice.ButtonText = NewText
	end)

	if not Choice.QuestTurnIn then
		return Container
	end

	Components.CreateLabel("Quest ID:", Container, 2)
	Components.CreateTextBox(Choice.QuestTurnIn.QuestId, Container, 3, false, function(NewQuestId)
		Choice.QuestTurnIn.QuestId = NewQuestId
	end)

	Components.CreateLabel("Success Response:", Container, 4)
	Components.CreateTextBox(Choice.QuestTurnIn.ResponseText, Container, 5, true, function(NewText)
		Choice.QuestTurnIn.ResponseText = NewText
	end)

	Components.CreateButton("Delete Choice", Container, 100, Constants.COLORS.Danger, OnDelete)

	return Container
end

return QuestTurnInEditor