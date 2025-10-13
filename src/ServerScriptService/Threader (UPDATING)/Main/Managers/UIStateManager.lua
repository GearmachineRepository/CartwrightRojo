--!strict
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local UIStateManager = {}

local SelectedNode: DialogNode? = nil
local SelectedChoice: DialogChoice? = nil
local FocusedElement: GuiObject? = nil
local CollapsedSections: {[string]: boolean} = {}
local CurrentView: string = "Editor"

type EventSubscribers = {[string]: {(any) -> ()}}
local Subscribers: EventSubscribers = {
	SelectionChanged = {},
	CollapseChanged = {},
	FocusChanged = {},
	ViewChanged = {}
}

function UIStateManager.Initialize()
	SelectedNode = nil
	SelectedChoice = nil
	FocusedElement = nil
	CollapsedSections = {}
	CurrentView = "Editor"
end

function UIStateManager.SelectNode(Node: DialogNode?)
	SelectedNode = Node
	SelectedChoice = nil

	for _, Callback in ipairs(Subscribers.SelectionChanged) do
		Callback(Node)
	end
end

function UIStateManager.SelectChoice(Choice: DialogChoice?)
	SelectedChoice = Choice
	SelectedNode = nil

	for _, Callback in ipairs(Subscribers.SelectionChanged) do
		Callback(Choice)
	end
end

function UIStateManager.GetSelectedNode(): DialogNode?
	return SelectedNode
end

function UIStateManager.GetSelectedChoice(): DialogChoice?
	return SelectedChoice
end

function UIStateManager.ClearSelection()
	SelectedNode = nil
	SelectedChoice = nil

	for _, Callback in ipairs(Subscribers.SelectionChanged) do
		Callback(nil)
	end
end

function UIStateManager.SetCollapsed(Id: string, IsCollapsed: boolean)
	CollapsedSections[Id] = IsCollapsed

	for _, Callback in ipairs(Subscribers.CollapseChanged) do
		Callback({Id = Id, IsCollapsed = IsCollapsed})
	end
end

function UIStateManager.IsCollapsed(Id: string): boolean
	return CollapsedSections[Id] or false
end

function UIStateManager.SetFocused(Element: GuiObject?)
	FocusedElement = Element

	for _, Callback in ipairs(Subscribers.FocusChanged) do
		Callback(Element)
	end
end

function UIStateManager.GetFocused(): GuiObject?
	return FocusedElement
end

function UIStateManager.SetCurrentView(View: string)
	CurrentView = View

	for _, Callback in ipairs(Subscribers.ViewChanged) do
		Callback(View)
	end
end

function UIStateManager.GetCurrentView(): string
	return CurrentView
end

function UIStateManager.Subscribe(EventType: string, Callback: (any) -> ())
	if Subscribers[EventType] then
		table.insert(Subscribers[EventType], Callback)
	end
end

function UIStateManager.Unsubscribe(EventType: string, Callback: (any) -> ())
	if Subscribers[EventType] then
		for Index, StoredCallback in ipairs(Subscribers[EventType]) do
			if StoredCallback == Callback then
				table.remove(Subscribers[EventType], Index)
				return
			end
		end
	end
end

return UIStateManager