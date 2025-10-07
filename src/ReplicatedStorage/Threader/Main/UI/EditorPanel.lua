--!strict
local Constants = require(script.Parent.Parent.Constants)
local Components = require(script.Parent.Components)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local ChoiceEditor = require(script.Parent.Parent.Editors.ChoiceEditor)

type DialogNode = DialogTree.DialogNode

local EditorPanel = {}

local function ElevateEditorZ(EditorFrame: Frame, EditorScroll: ScrollingFrame)
	EditorFrame.ZIndex = 100
	EditorScroll.ZIndex = 101

	local function ShouldSkipZIndexOverride(Obj: GuiObject): boolean
		if Obj:GetAttribute("IsDropdownOptions") then
			return true
		end

		local Parent = Obj.Parent
		while Parent do
			if Parent:IsA("GuiObject") and Parent:GetAttribute("IsDropdownOptions") then
				return true
			end
			Parent = Parent.Parent
		end

		return false
	end

	for _, Obj in ipairs(EditorScroll:GetDescendants()) do
		if Obj:IsA("GuiObject") and not ShouldSkipZIndexOverride(Obj) then
			Obj.ZIndex = 102
		end
	end

	EditorScroll.DescendantAdded:Connect(function(Obj)
		if Obj:IsA("GuiObject") and not ShouldSkipZIndexOverride(Obj) then
			Obj.ZIndex = 102
		end
	end)
end

local EditorFrame: Frame

function EditorPanel.Create(Parent: Instance): ScrollingFrame
	EditorFrame = Instance.new("Frame")
	EditorFrame.Size = UDim2.new(Constants.SIZES.EditorWidth, -10, 1, -Constants.SIZES.TopBarHeight - 10)
	EditorFrame.Position = UDim2.new(Constants.SIZES.TreeViewWidth, 5, 0, Constants.SIZES.TopBarHeight + 5)
	EditorFrame.BackgroundColor3 = Constants.COLORS.BackgroundLight
	EditorFrame.BorderSizePixel = 0
	EditorFrame.Parent = Parent

	local EditorScroll = Instance.new("ScrollingFrame")
	EditorScroll.Size = UDim2.fromScale(1, 1)
	EditorScroll.BackgroundTransparency = 1
	EditorScroll.ScrollBarThickness = Constants.SIZES.ScrollBarThickness
	EditorScroll.Parent = EditorFrame

	local EditorLayout = Instance.new("UIListLayout")
	EditorLayout.Padding = UDim.new(0, Constants.SIZES.Padding)
	EditorLayout.SortOrder = Enum.SortOrder.LayoutOrder
	EditorLayout.Parent = EditorScroll

	local EditorPadding = Instance.new("UIPadding")
	EditorPadding.PaddingLeft = UDim.new(0, Constants.SIZES.Padding)
	EditorPadding.PaddingRight = UDim.new(0, Constants.SIZES.Padding)
	EditorPadding.PaddingTop = UDim.new(0, Constants.SIZES.Padding)
	EditorPadding.Parent = EditorScroll

	EditorLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		EditorScroll.CanvasSize = UDim2.fromOffset(0, EditorLayout.AbsoluteContentSize.Y + Constants.SIZES.Padding * 2)
	end)

	ElevateEditorZ(EditorFrame, EditorScroll)

	return EditorScroll
end

function EditorPanel.UpdateSize(DividerPosition: number)
	if EditorFrame then
		EditorFrame.Size = UDim2.new(1 - DividerPosition, -10, 1, -Constants.SIZES.TopBarHeight - 10)
		EditorFrame.Position = UDim2.new(DividerPosition, 5, 0, Constants.SIZES.TopBarHeight + 5)
	end
end

function EditorPanel.Refresh(
	EditorScroll: ScrollingFrame,
	SelectedNode: DialogNode?,
	OnRefresh: () -> (),
	OnNavigate: (DialogNode) -> (),
	CurrentTree: DialogNode?
)
	ChoiceEditor.SetCurrentTree(CurrentTree)

	for _, Child in ipairs(EditorScroll:GetChildren()) do
		if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
			Child:Destroy()
		end
	end

	if not SelectedNode then
		local Label = Instance.new("TextLabel")
		Label.Size = UDim2.new(1, 0, 0, 40)
		Label.Text = "Select a node to edit"
		Label.TextColor3 = Constants.COLORS.TextMuted
		Label.BackgroundTransparency = 1
		Label.Font = Constants.FONTS.Medium
		Label.TextSize = Constants.TEXT_SIZES.Large
		Label.Parent = EditorScroll
		return
	end

	-- NODE TYPE INDICATOR
	local NodeTypeFrame = Instance.new("Frame")
	NodeTypeFrame.Size = UDim2.new(1, 0, 0, 36)
	NodeTypeFrame.BackgroundColor3 = Constants.COLORS.Primary
	NodeTypeFrame.BorderSizePixel = 0
	NodeTypeFrame.LayoutOrder = 0
	NodeTypeFrame.Parent = EditorScroll

	local NodeTypeCorner = Instance.new("UICorner")
	NodeTypeCorner.CornerRadius = UDim.new(0, 6)
	NodeTypeCorner.Parent = NodeTypeFrame

	local NodeTypeLabel = Instance.new("TextLabel")
	NodeTypeLabel.Size = UDim2.fromScale(1, 1)
	NodeTypeLabel.Text = "DIALOG/RESPONSE NODE"
	NodeTypeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	NodeTypeLabel.BackgroundTransparency = 1
	NodeTypeLabel.Font = Constants.FONTS.Bold
	NodeTypeLabel.TextSize = 14
	NodeTypeLabel.Parent = NodeTypeFrame

	-- REST OF THE FUNCTION CONTINUES WITH NODE ID, DIALOG TEXT, ETC...
	Components.CreateLabel("Node ID:", EditorScroll, 1)
	Components.CreateTextBox(SelectedNode.Id, EditorScroll, 2, false, function(NewId: string)
		SelectedNode.Id = NewId
		OnRefresh()
	end)

	Components.CreateLabel("Dialog Text:", EditorScroll, 3)
	Components.CreateTextBox(SelectedNode.Text, EditorScroll, 4, true, function(NewText: string)
		SelectedNode.Text = NewText
		OnRefresh()
	end)

	local _, GreetingsContent = Components.CreateCollapsibleSection(
		"Conditional Greetings",
		EditorScroll,
		3,
		true
	)

	if not SelectedNode.Greetings then
		SelectedNode.Greetings = {}
	end

	for Index, Greeting in ipairs(SelectedNode.Greetings) do
		local GreetingContainer = Components.CreateContainer(GreetingsContent, Index)

		Components.CreateLabel("Condition Type:", GreetingContainer, 1)
		Components.CreateDropdown(
			{"HasQuest", "CompletedQuest", "DialogFlag"},
			Greeting.ConditionType,
			GreetingContainer,
			2,
			function(NewType: string)
				Greeting.ConditionType = NewType
				OnRefresh()
			end
		)

		Components.CreateLabel("Condition Value:", GreetingContainer, 3)
		Components.CreateTextBox(Greeting.ConditionValue, GreetingContainer, 4, false, function(NewValue: string)
			Greeting.ConditionValue = NewValue
		end)

		Components.CreateLabel("Greeting Text:", GreetingContainer, 5)
		Components.CreateTextBox(Greeting.GreetingText, GreetingContainer, 6, true, function(NewText: string)
			Greeting.GreetingText = NewText
		end)

		Components.CreateButton("Delete Greeting", GreetingContainer, 100, Constants.COLORS.Danger, function()
			DialogTree.RemoveGreeting(SelectedNode, Index)
			OnRefresh()
		end)
	end

	Components.CreateButton("+ Add Greeting", GreetingsContent, 1000, Constants.COLORS.Accent, function()
		DialogTree.AddGreeting(SelectedNode, "HasQuest", "QuestID", "Greeting text...")
		OnRefresh()
	end)

	Components.CreateLabel("Choices:", EditorScroll, 4)

	if not SelectedNode.Choices then
		SelectedNode.Choices = {}
	end

	local ChoicesContainer = Instance.new("Frame")
	ChoicesContainer.Name = "ChoicesContainer"
	ChoicesContainer.Size = UDim2.new(1, 0, 0, 100)
	ChoicesContainer.BackgroundTransparency = 1
	ChoicesContainer.LayoutOrder = 7
	ChoicesContainer.Parent = EditorScroll

	local ChoicesLayout = Instance.new("UIListLayout")
	ChoicesLayout.Padding = UDim.new(0, 12)
	ChoicesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ChoicesLayout.Parent = ChoicesContainer

	for Index, Choice in ipairs(SelectedNode.Choices) do
		ChoiceEditor.Render(
			Choice,
			Index,
			ChoicesContainer,
			Index,
			function()
				DialogTree.RemoveChoice(SelectedNode, Index)
				OnRefresh()
			end,
			OnNavigate,
			OnRefresh
		)
	end

	ChoicesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ChoicesContainer.Size = UDim2.new(1, 0, 0, ChoicesLayout.AbsoluteContentSize.Y)
	end)

	Components.CreateButton("+ Add Choice", EditorScroll, 1000, Constants.COLORS.Primary, function()
		DialogTree.AddChoice(SelectedNode, DialogTree.CreateChoice("New choice"))
		OnRefresh()
	end)

	ElevateEditorZ(EditorScroll.Parent :: Frame, EditorScroll)
end

return EditorPanel