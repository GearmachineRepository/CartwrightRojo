--!strict
local NodeEditor = require(script.Parent.NodeEditor)
local Builder = require(script.Parent.Parent.Components.Builder)
local UIStateManager = require(script.Parent.Parent.Managers.UIStateManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)
local FlagsManagerWindow = require(script.Parent.Parent.Windows.FlagsManagerWindow)

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
				ButtonText = "New choice",
				ResponseNode = DialogTree.CreateNode("response_new", "Response text..."),
				ResponseType = DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE
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
	local ChoiceSection, ChoiceContent = NodeEditor.CreateCollapsibleSection(
		Parent,
		"Choice " .. Index .. ": " .. (Choice.ButtonText or "Untitled"):sub(1, 30),
		true
	)
	ChoiceSection.LayoutOrder = Index

	local HeaderRow = Instance.new("Frame")
	HeaderRow.Size = UDim2.new(1, 0, 0, 32)
	HeaderRow.BackgroundTransparency = 1
	HeaderRow.LayoutOrder = 0
	HeaderRow.Parent = ChoiceContent

	local HeaderLayout = Instance.new("UIListLayout")
	HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderLayout.Padding = UDim.new(0, 8)
	HeaderLayout.Parent = HeaderRow

	local DeleteButton = Builder.Button({
		Text = "Delete Choice",
		Type = "Danger",
		OnClick = function()
			table.remove(ParentNode.Choices, Index)
			OnRefresh()
		end
	})
	DeleteButton.Size = UDim2.new(0, 120, 0, 28)
	DeleteButton.Parent = HeaderRow

	Builder.Spacer(4).Parent = ChoiceContent

	Builder.LabeledInput("Button Text:", {
		Value = Choice.ButtonText or "",
		PlaceholderText = "Enter choice button text...",
		OnChanged = function(Text)
			Choice.ButtonText = Text
			OnRefresh()
		end
	}).Parent = ChoiceContent

	Builder.Spacer(8).Parent = ChoiceContent

	if not Choice.ResponseType then
		Choice.ResponseType = DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE
	end

	local ResponseTypeOptions = {
		"Show Response with Choices",
		"End Dialog",
		"Return to Start",
		"Return to Node",
		"Skill Check"
	}

	local CurrentResponseType = "Show Response with Choices"
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
		CurrentResponseType = "End Dialog"
	elseif Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
		CurrentResponseType = "Return to Start"
	elseif Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		CurrentResponseType = "Return to Node"
	elseif Choice.SkillCheck then
		CurrentResponseType = "Skill Check"
	end

	Builder.Label("Response Type:").Parent = ChoiceContent
	Builder.Dropdown({
		Options = ResponseTypeOptions,
		Selected = CurrentResponseType,
		OnSelected = function(Selected: string)
			if Selected == "Show Response with Choices" then
				Choice.ResponseType = DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE
				Choice.SkillCheck = nil
				if not Choice.ResponseNode then
					Choice.ResponseNode = DialogTree.CreateNode("response_" .. Index, "Response text...")
				end
			elseif Selected == "End Dialog" then
				Choice.ResponseType = DialogTree.RESPONSE_TYPES.END_DIALOG
				Choice.SkillCheck = nil
				Choice.ResponseNode = nil
			elseif Selected == "Return to Start" then
				Choice.ResponseType = DialogTree.RESPONSE_TYPES.RETURN_TO_START
				Choice.SkillCheck = nil
				Choice.ResponseNode = nil
			elseif Selected == "Return to Node" then
				Choice.ResponseType = DialogTree.RESPONSE_TYPES.RETURN_TO_NODE
				Choice.SkillCheck = nil
				Choice.ResponseNode = nil
			elseif Selected == "Skill Check" then
				Choice.SkillCheck = {
					Skill = "Perception",
					Difficulty = 10,
					SuccessNode = DialogTree.CreateNode("success_" .. Index, "Success!"),
					FailureNode = DialogTree.CreateNode("failure_" .. Index, "Failure!")
				}
			end
			OnRefresh()
		end
	}).Parent = ChoiceContent

	Builder.Spacer(8).Parent = ChoiceContent

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		Builder.LabeledInput("Return To Node ID:", {
			Value = Choice.ReturnToNodeId or "",
			PlaceholderText = "Enter target node ID...",
			OnChanged = function(Text)
				Choice.ReturnToNodeId = Text ~= "" and Text or nil
				OnRefresh()
			end
		}).Parent = ChoiceContent
	end

	if Choice.SkillCheck then
		ChoiceEditor.RenderSkillCheckSection(ChoiceContent, Choice, OnRefresh)
	elseif Choice.ResponseNode then
		ChoiceEditor.RenderResponseSection(ChoiceContent, Choice, OnRefresh)
	end

	Builder.Spacer(8).Parent = ChoiceContent

	local ConditionsSection, ConditionsContent = NodeEditor.CreateCollapsibleSection(
		ChoiceContent,
		"Conditions (When Choice Appears)",
		true
	)

	if not Choice.Conditions then
		Choice.Conditions = {}
	end

	for CondIndex, Condition in ipairs(Choice.Conditions) do
		ChoiceEditor.RenderCondition(ConditionsContent, Condition, CondIndex, Choice, OnRefresh)
	end

	Builder.Button({
		Text = "+ Add Condition",
		Type = "Success",
		OnClick = function()
			table.insert(Choice.Conditions, {
				Type = "HasFlag",
				Value = "None"
			})
			OnRefresh()
		end
	}).Parent = ConditionsContent

	Builder.Spacer(8).Parent = ChoiceContent

	local FlagsSection, FlagsContent = NodeEditor.CreateCollapsibleSection(
		ChoiceContent,
		"Set Flags (On Click)",
		true
	)

	if not Choice.SetFlags then
		Choice.SetFlags = {}
	end

	for FlagIndex, FlagName in ipairs(Choice.SetFlags) do
		ChoiceEditor.RenderFlag(FlagsContent, FlagName, FlagIndex, Choice, OnRefresh)
	end

	Builder.Button({
		Text = "+ Add Flag",
		Type = "Success",
		OnClick = function()
			table.insert(Choice.SetFlags, "NewFlag")
			OnRefresh()
		end
	}).Parent = FlagsContent
end

function ChoiceEditor.RenderResponseSection(Parent: Frame, Choice: DialogChoice, OnRefresh: () -> ())
	if not Choice.ResponseNode then return end

	Builder.Label("Response Node:").Parent = Parent
	Builder.LabeledInput("Response ID:", {
		Value = Choice.ResponseNode.Id or "",
		PlaceholderText = "Enter response ID...",
		OnChanged = function(Text)
			Choice.ResponseNode.Id = Text
			OnRefresh()
		end
	}).Parent = Parent

	Builder.LabeledInput("Response Text:", {
		Value = Choice.ResponseNode.Text or "",
		PlaceholderText = "Enter response text...",
		Multiline = true,
		Height = 80,
		OnChanged = function(Text)
			Choice.ResponseNode.Text = Text
			OnRefresh()
		end
	}).Parent = Parent
end

function ChoiceEditor.RenderSkillCheckSection(Parent: Frame, Choice: DialogChoice, OnRefresh: () -> ())
	if not Choice.SkillCheck then return end

	Builder.Label("Skill Check Settings:").Parent = Parent

	local SkillOptions = {"Perception", "Charisma", "Intelligence", "Strength", "Agility", "Wisdom"}

	Builder.Label("Skill:").Parent = Parent
	Builder.Dropdown({
		Options = SkillOptions,
		Selected = Choice.SkillCheck.Skill or "Perception",
		OnSelected = function(Selected: string)
			Choice.SkillCheck.Skill = Selected
			OnRefresh()
		end
	}).Parent = Parent

	Builder.Label("Difficulty:").Parent = Parent
	Builder.NumberInput({
		Value = Choice.SkillCheck.Difficulty or 10,
		Min = 1,
		Max = 30,
		OnChanged = function(Value: number)
			Choice.SkillCheck.Difficulty = Value
			OnRefresh()
		end
	}).Parent = Parent

	Builder.Spacer(8).Parent = Parent

	if Choice.SkillCheck.SuccessNode then
		Builder.Label("Success Response:").Parent = Parent
		Builder.LabeledInput("Success Text:", {
			Value = Choice.SkillCheck.SuccessNode.Text or "",
			PlaceholderText = "Enter success response...",
			Multiline = true,
			Height = 60,
			OnChanged = function(Text)
				Choice.SkillCheck.SuccessNode.Text = Text
				OnRefresh()
			end
		}).Parent = Parent
	end

	if Choice.SkillCheck.FailureNode then
		Builder.Label("Failure Response:").Parent = Parent
		Builder.LabeledInput("Failure Text:", {
			Value = Choice.SkillCheck.FailureNode.Text or "",
			PlaceholderText = "Enter failure response...",
			Multiline = true,
			Height = 60,
			OnChanged = function(Text)
				Choice.SkillCheck.FailureNode.Text = Text
				OnRefresh()
			end
		}).Parent = Parent
	end
end

function ChoiceEditor.RenderCondition(Parent: Frame, Condition: any, Index: number, Choice: DialogChoice, OnRefresh: () -> ())
	local ConditionFrame = Instance.new("Frame")
	ConditionFrame.Size = UDim2.new(1, 0, 0, 100)
	ConditionFrame.BackgroundTransparency = 1
	ConditionFrame.LayoutOrder = Index
	ConditionFrame.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 4)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = ConditionFrame

	Builder.Label("Condition " .. Index .. ":").Parent = ConditionFrame

	local ConditionTypes = {"HasFlag", "MissingFlag", "LevelGreaterThan", "HasItem"}

	Builder.Dropdown({
		Options = ConditionTypes,
		Selected = Condition.Type or "HasFlag",
		OnSelected = function(Selected: string)
			Condition.Type = Selected
			OnRefresh()
		end
	}).Parent = ConditionFrame

	if Condition.Type == "HasFlag" or Condition.Type == "MissingFlag" then
		local AvailableFlags = FlagsManagerWindow.GetFlags()
		Builder.Dropdown({
			Options = AvailableFlags,
			Selected = Condition.Value or "None",
			OnSelected = function(Selected: string)
				Condition.Value = Selected
				OnRefresh()
			end
		}).Parent = ConditionFrame
	else
		Builder.TextBox({
			Value = tostring(Condition.Value or ""),
			PlaceholderText = "Enter value...",
			OnChanged = function(Text)
				Condition.Value = Text
				OnRefresh()
			end
		}).Parent = ConditionFrame
	end

	Builder.Button({
		Text = "Delete",
		Type = "Danger",
		OnClick = function()
			table.remove(Choice.Conditions, Index)
			OnRefresh()
		end
	}).Parent = ConditionFrame

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ConditionFrame.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
	end)
end

function ChoiceEditor.RenderFlag(Parent: Frame, FlagName: string, Index: number, Choice: DialogChoice, OnRefresh: () -> ())
	local FlagFrame = Instance.new("Frame")
	FlagFrame.Size = UDim2.new(1, 0, 0, 60)
	FlagFrame.BackgroundTransparency = 1
	FlagFrame.LayoutOrder = Index
	FlagFrame.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 4)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = FlagFrame

	Builder.Label("Flag " .. Index .. ":").Parent = FlagFrame

	local AvailableFlags = FlagsManagerWindow.GetFlags()
	Builder.Dropdown({
		Options = AvailableFlags,
		Selected = FlagName or "None",
		OnSelected = function(Selected: string)
			Choice.SetFlags[Index] = Selected
			OnRefresh()
		end
	}).Parent = FlagFrame

	Builder.Button({
		Text = "Delete",
		Type = "Danger",
		OnClick = function()
			table.remove(Choice.SetFlags, Index)
			OnRefresh()
		end
	}).Parent = FlagFrame

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		FlagFrame.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
	end)
end

function ChoiceEditor.RenderChoice(Parent: ScrollingFrame, Choice: DialogChoice, OnRefresh: () -> ())
	local Base = NodeEditor.CreateBase(Parent, "Choice Editor")

	local Section = NodeEditor.CreateSection(Base.Container, "Choice Properties", 1)

	Builder.LabeledInput("Button Text:", {
		Value = Choice.ButtonText or "",
		PlaceholderText = "Enter choice text...",
		OnChanged = function(Text)
			Choice.ButtonText = Text
			OnRefresh()
		end
	}).Parent = Section

	if Choice.ResponseNode then
		Builder.LabeledInput("Response Text:", {
			Value = Choice.ResponseNode.Text or "",
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