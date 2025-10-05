--!strict
local Components = require(script.Parent.Parent.UI.Components)
--local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local QuestEditor = {}

function QuestEditor.Render(
	_: DialogChoice, -- Choice
	_: number, -- Index
	Parent: Instance,
	Order: number,
	_: () -> (),  -- OnDelete
	_: (DialogTree.DialogNode) -> ()  -- OnNavigate
): Frame
	local Container = Components.CreateContainer(Parent, Order)

	Components.CreateLabel("Quest Editor - Coming Soon!", Container, 1)
	Components.CreateLabel("This will allow quest giving and turn-ins.", Container, 2)

	return Container
end

return QuestEditor