--!strict
local NodeEditor = require(script.Parent.NodeEditor)
local Builder = require(script.Parent.Parent.Components.Builder)
local UIStateManager = require(script.Parent.Parent.Managers.UIStateManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local ChoiceEditor = {}

function ChoiceEditor.Render(Parent: ScrollingFrame, Node: DialogNode, OnRefresh: () -> ())
	local Base = NodeEditor.CreateBase(Parent, "Node Editor")

	local BasicSection = NodeEditor.CreateSection(Base.Container, "Node Properties", 1)

	Builder.LabeledInput("Node ID:", {
		Value = Node.Id,
		PlaceholderText = "Enter node ID...",
		OnChanged = function(Text)
			Node.Id = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.LabeledInput("Dialog Text:", {
		Value = Node.Text,
		PlaceholderText = "Enter dialog text...",
		Multiline = true,
		Height = 100,
		OnChanged = function(Text)
			Node.Text = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.Spacer(12).Parent = Base.Container

	local ChoicesSection, ChoicesContent = NodeEditor.CreateCollapsibleSection(
		Base.Container,
		"Choices (" .. (Node.Choices and #Node.Choices or 0) .. ")",
		false
	)
	ChoicesSection.LayoutOrder = 2

	if not Node.Choices then
		Node.Choices = {}
	end

	for Index, Choice in ipairs(Node.Choices) do
		ChoiceEditor.RenderChoiceItem(ChoicesContent, Choice, Index, Node, OnRefresh, Base.Connections)
	end

	Builder.Spacer(8).Parent = ChoicesContent

	local AddChoiceButton = Builder.Button({
		Text = "+ Add Choice",
		Type = "Success",
		OnClick = function()
			local NewChoice: DialogChoice = {
				Text = "New choice",
				ResponseNode = nil
			}
			table.insert(Node.Choices, NewChoice)
			OnRefresh()
		end
	})
	AddChoiceButton.Size = UDim2.new(0, 150, 0, 32)
	AddChoiceButton.Parent = ChoicesContent

	Builder.Spacer(12).Parent = Base.Container

	local AdvancedSection, AdvancedContent = NodeEditor.CreateCollapsibleSection(
		Base.Container,
		"Advanced Settings",
		true
	)
	AdvancedSection.LayoutOrder = 3

	Builder.LabeledInput("Return To Node ID:", {
		Value = Node.ReturnToNodeId or "",
		PlaceholderText = "Leave empty or enter node ID...",
		OnChanged = function(Text)
			Node.ReturnToNodeId = Text ~= "" and Text or nil
			OnRefresh()
		end
	}).Parent = AdvancedContent

	Builder.LabeledInput("Commands:", {
		Value = Node.Command or "",
		PlaceholderText = "Enter Lua commands...",
		Multiline = true,
		Height = 80,
		OnChanged = function(Text)
			Node.Command = Text ~= "" and Text or nil
			OnRefresh()
		end
	}).Parent = AdvancedContent
end

function ChoiceEditor.RenderChoiceItem(Parent: Frame, Choice: DialogChoice, Index: number, ParentNode: DialogNode, OnRefresh: () -> (), Connections: any)
	local ChoiceSection = NodeEditor.CreateSection(Parent, nil, Index)

	local HeaderRow = Instance.new("Frame")
	HeaderRow.Size = UDim2.new(1, 0, 0, 32)
	HeaderRow.BackgroundTransparency = 1
	HeaderRow.LayoutOrder = 0
	HeaderRow.Parent = ChoiceSection

	local HeaderLayout = Instance.new("UIListLayout")
	HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderLayout.Padding = UDim.new(0, 8)
	HeaderLayout.Parent = HeaderRow

	local ChoiceLabel = Builder.Label("Choice " .. Index, {Bold = true})
	ChoiceLabel.Size = UDim2.new(1, -80, 1, 0)
	ChoiceLabel.Parent = HeaderRow

	local DeleteButton = Builder.Button({
		Text = "Delete",
		Type = "Danger",
		OnClick = function()
			table.remove(ParentNode.Choices, Index)
			OnRefresh()
		end
	})
	DeleteButton.Size = UDim2.new(0, 70, 0, 28)
	DeleteButton.Parent = HeaderRow

	Builder.Spacer(4).Parent = ChoiceSection

	Builder.LabeledInput("Button Text:", {
		Value = Choice.Text,
		PlaceholderText = "Enter choice text...",
		OnChanged = function(Text)
			Choice.Text = Text
			OnRefresh()
		end
	}).Parent = ChoiceSection

	local ResponseContainer = Instance.new("Frame")
	ResponseContainer.Size = UDim2.new(1, 0, 0, 32)
	ResponseContainer.BackgroundTransparency = 1
	ResponseContainer.Parent = ChoiceSection

	local ResponseLayout = Instance.new("UIListLayout")
	ResponseLayout.FillDirection = Enum.FillDirection.Horizontal
	ResponseLayout.Padding = UDim.new(0, 8)
	ResponseLayout.Parent = ResponseContainer

	local ResponseLabel = Builder.Label("Response Node:")
	ResponseLabel.Size = UDim2.new(0, 120, 1, 0)
	ResponseLabel.Parent = ResponseContainer

	if Choice.ResponseNode then
		local RemoveButton = Builder.Button({
			Text = "Remove Response",
			Type = "Danger",
			OnClick = function()
				Choice.ResponseNode = nil
				OnRefresh()
			end
		})
		RemoveButton.Size = UDim2.new(0, 150, 0, 28)
		RemoveButton.Parent = ResponseContainer
	else
		local AddButton = Builder.Button({
			Text = "Add Response",
			Type = "Success",
			OnClick = function()
				Choice.ResponseNode = DialogTree.CreateNode("response_" .. Index, "Enter response text...")
				OnRefresh()
			end
		})
		AddButton.Size = UDim2.new(0, 150, 0, 28)
		AddButton.Parent = ResponseContainer
	end

	Builder.Spacer(8).Parent = ChoiceSection
end

function ChoiceEditor.RenderChoice(Parent: ScrollingFrame, Choice: DialogChoice, OnRefresh: () -> ())
	local Base = NodeEditor.CreateBase(Parent, "Choice Editor")

	local Section = NodeEditor.CreateSection(Base.Container, "Choice Properties", 1)

	Builder.LabeledInput("Button Text:", {
		Value = Choice.Text,
		PlaceholderText = "Enter choice text...",
		OnChanged = function(Text)
			Choice.Text = Text
			OnRefresh()
		end
	}).Parent = Section

	if Choice.ResponseNode then
		Builder.LabeledInput("Response Text:", {
			Value = Choice.ResponseNode.Text,
			PlaceholderText = "Enter response text...",
			Multiline = true,
			Height = 100,
			OnChanged = function(Text)
				Choice.ResponseNode.Text = Text
				OnRefresh()
			end
		}).Parent = Section
	end
end

return ChoiceEditor