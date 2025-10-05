--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local SimpleChoiceEditor = {}

function SimpleChoiceEditor.Render(
	Choice: DialogChoice,
	Index: number,
	Parent: Instance,
	Order: number,
	OnDelete: () -> (),
	OnNavigate: (DialogTree.DialogNode) -> ()
): Frame
	local Container = Components.CreateContainer(Parent, Order)

	Components.CreateLabel("Choice " .. tostring(Index) .. " - Button Text:", Container, 1)
	Components.CreateTextBox(Choice.ButtonText, Container, 2, false, function(NewText)
		Choice.ButtonText = NewText
	end)

	if Choice.ResponseNode then
		Components.CreateLabel("Response Text:", Container, 3)
		Components.CreateTextBox(Choice.ResponseNode.Text, Container, 4, true, function(NewText)
			Choice.ResponseNode.Text = NewText
		end)

		Components.CreateButton("Edit Response Branch →", Container, 5, Constants.COLORS.Primary, function()
			OnNavigate(Choice.ResponseNode)
		end)
	end

	Components.CreateButton("Delete Choice", Container, 100, Constants.COLORS.Danger, OnDelete)

	return Container
end

return SimpleChoiceEditor