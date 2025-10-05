--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice
type DialogNode = DialogTree.DialogNode

local BaseEditor = {}

export type EditorCallbacks = {
	OnDelete: () -> (),
	OnNavigate: (DialogNode) -> (),
	OnRefresh: () -> ()
}

function BaseEditor.CreateChoiceHeader(
	Choice: DialogChoice,
	Index: number,
	Container: Frame,
	OnTextChanged: (string) -> ()
)
	Components.CreateLabel("Choice " .. tostring(Index) .. " - Button Text:", Container, 1)
	Components.CreateTextBox(Choice.ButtonText, Container, 2, false, OnTextChanged)
end

function BaseEditor.CreateDeleteButton(
	Container: Frame,
	OnDelete: () -> ()
)
	Components.CreateButton("Delete Choice", Container, 100, Constants.COLORS.Danger, OnDelete)
end

function BaseEditor.CreateNavigationButton(
	ButtonText: string,
	Container: Frame,
	Order: number,
	Color: Color3,
	TargetNode: DialogNode?,
	OnNavigate: (DialogNode) -> ()
)
	if not TargetNode then return end

	Components.CreateButton(ButtonText, Container, Order, Color, function()
		OnNavigate(TargetNode)
	end)
end

function BaseEditor.CreateResponseSection(
	Title: string,
	ResponseNode: DialogNode?,
	Container: Frame,
	StartOrder: number,
	OnTextChanged: (string) -> (),
	ButtonText: string,
	ButtonColor: Color3,
	OnNavigate: (DialogNode) -> ()
): number
	Components.CreateLabel(Title, Container, StartOrder)

	if ResponseNode then
		Components.CreateTextBox(ResponseNode.Text, Container, StartOrder + 1, true, OnTextChanged)
		BaseEditor.CreateNavigationButton(ButtonText, Container, StartOrder + 2, ButtonColor, ResponseNode, OnNavigate)
		return StartOrder + 3
	end

	return StartOrder + 1
end

return BaseEditor