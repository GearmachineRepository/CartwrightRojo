--!strict
local Components = require(script.Parent.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local ChoiceEditor = require(script.Parent.Parent.Editors.ChoiceEditor)
local Prompt = require(script.Parent.Parent.UI.Prompt)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local EditorPanel = {}
local EditorFrame: Frame

local function ElevateEditorZ(ParentFrame: Frame, ScrollFrame: ScrollingFrame)
	ParentFrame.ZIndex = 100
	ScrollFrame.ZIndex = 101

	for _, Descendant in ipairs(ScrollFrame:GetDescendants()) do
		if Descendant:IsA("GuiObject") then
			Descendant.ZIndex = Descendant.ZIndex + 100
		end
	end
end

local function FindChoicesPointingToNode(RootNode: DialogNode?, TargetNode: DialogNode?): {DialogChoice}
	local FoundChoices: {DialogChoice} = {}

	if not RootNode or not TargetNode then
		return FoundChoices
	end

	local function SearchNode(Node: DialogNode)
		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode == TargetNode then
					table.insert(FoundChoices, Choice)
				end

				if Choice.ReturnToNodeId == TargetNode.Id then
					table.insert(FoundChoices, Choice)
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						SearchNode(Choice.SkillCheck.SuccessNode)
					end
					if Choice.SkillCheck.FailureNode then
						SearchNode(Choice.SkillCheck.FailureNode)
					end
				elseif Choice.ResponseNode then
					SearchNode(Choice.ResponseNode)
				end
			end
		end
	end

	SearchNode(RootNode)
	return FoundChoices
end

local function FindParentNodeForChoice(RootNode: DialogNode?, TargetChoice: DialogChoice?): DialogNode?
	if not RootNode or not TargetChoice then
		return nil
	end

	local function SearchNode(Node: DialogNode): DialogNode?
		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice == TargetChoice then
					return Node
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						local Found = SearchNode(Choice.SkillCheck.SuccessNode)
						if Found then return Found end
					end
					if Choice.SkillCheck.FailureNode then
						local Found = SearchNode(Choice.SkillCheck.FailureNode)
						if Found then return Found end
					end
				elseif Choice.ResponseNode then
					local Found = SearchNode(Choice.ResponseNode)
					if Found then return Found end
				end
			end
		end
		return nil
	end

	return SearchNode(RootNode)
end

function EditorPanel.Create(Parent: Frame): ScrollingFrame
	EditorFrame = Instance.new("Frame")
	EditorFrame.Name = "EditorPanel"
	EditorFrame.Size = UDim2.new(0.45, -10, 1, -Constants.SIZES.TopBarHeight - 10)
	EditorFrame.Position = UDim2.new(0.55, 5, 0, Constants.SIZES.TopBarHeight + 5)
	EditorFrame.BackgroundColor3 = Constants.COLORS.Panel
	EditorFrame.BorderSizePixel = 1
	EditorFrame.BorderColor3 = Constants.COLORS.Border
	EditorFrame.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = EditorFrame

	local EditorScroll = Instance.new("ScrollingFrame")
	EditorScroll.Name = "EditorScroll"
	EditorScroll.Size = UDim2.fromScale(1, 1)
	EditorScroll.BackgroundTransparency = 1
	EditorScroll.ScrollBarThickness = 6
	EditorScroll.ScrollBarImageColor3 = Constants.COLORS.Border
	EditorScroll.BorderSizePixel = 0
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
	SelectedChoice: DialogChoice?,
	OnRefresh: () -> (),
	OnNavigateToNode: (DialogNode) -> (),
	OnNavigateToChoice: (DialogChoice) -> (),
	CurrentTree: DialogNode?
)
	ChoiceEditor.SetCurrentTree(CurrentTree)

	for _, Child in ipairs(EditorScroll:GetChildren()) do
		if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
			Child:Destroy()
		end
	end

	if SelectedChoice then
		EditorPanel.RenderChoiceEditor(EditorScroll, SelectedChoice, OnRefresh, OnNavigateToNode, OnNavigateToChoice, CurrentTree)
	elseif SelectedNode then
		EditorPanel.RenderNodeEditor(EditorScroll, SelectedNode, OnRefresh, OnNavigateToNode, OnNavigateToChoice, CurrentTree)
	else
		local Label = Instance.new("TextLabel")
		Label.Size = UDim2.new(1, 0, 0, 40)
		Label.Text = "Select a node or choice to edit"
		Label.TextColor3 = Constants.COLORS.TextMuted
		Label.BackgroundTransparency = 1
		Label.Font = Constants.FONTS.Medium
		Label.TextSize = Constants.TEXT_SIZES.Large
		Label.Parent = EditorScroll
	end

	ElevateEditorZ(EditorScroll.Parent :: Frame, EditorScroll)
end

function EditorPanel.RenderChoiceEditor(
	EditorScroll: ScrollingFrame,
	Choice: DialogChoice,
	OnRefresh: () -> (),
	OnNavigateToNode: (DialogNode) -> (),
	_: (DialogChoice) -> (),
	CurrentTree: DialogNode?
)
	local TypeFrame = Instance.new("Frame")
	TypeFrame.Size = UDim2.new(1, 0, 0, 36)
	TypeFrame.BackgroundColor3 = Constants.COLORS.Accent
	TypeFrame.BorderSizePixel = 0
	TypeFrame.LayoutOrder = 0
	TypeFrame.Parent = EditorScroll

	local TypeCorner = Instance.new("UICorner")
	TypeCorner.CornerRadius = UDim.new(0, 6)
	TypeCorner.Parent = TypeFrame

	local TypeLabel = Instance.new("TextLabel")
	TypeLabel.Size = UDim2.new(1, -100, 1, 0)
	TypeLabel.Text = "CHOICE"
	TypeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	TypeLabel.BackgroundTransparency = 1
	TypeLabel.Font = Constants.FONTS.Bold
	TypeLabel.TextSize = 14
	TypeLabel.Parent = TypeFrame

	local DeleteButton = Instance.new("TextButton")
	DeleteButton.Size = UDim2.fromOffset(80, 28)
	DeleteButton.Position = UDim2.new(1, -90, 0.5, -14)
	DeleteButton.Text = "Delete"
	DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
	DeleteButton.BorderSizePixel = 0
	DeleteButton.Font = Constants.FONTS.Medium
	DeleteButton.TextSize = 12
	DeleteButton.AutoButtonColor = false
	DeleteButton.Parent = TypeFrame

	local DeleteCorner = Instance.new("UICorner")
	DeleteCorner.CornerRadius = UDim.new(0, 4)
	DeleteCorner.Parent = DeleteButton

	DeleteButton.MouseButton1Click:Connect(function()
		local ParentNode = FindParentNodeForChoice(CurrentTree, Choice)
		if ParentNode and ParentNode.Choices then
			Prompt.CreateConfirmation(
				EditorScroll.Parent.Parent.Parent,
				"Delete Choice",
				"Are you sure you want to delete this choice? This action cannot be undone.",
				"Delete",
				function(Confirmed: boolean)
					if Confirmed then
						for Index, C in ipairs(ParentNode.Choices) do
							if C == Choice then
								DialogTree.RemoveChoice(ParentNode, Index)
								OnRefresh()
								break
							end
						end
					end
				end
			)
		end
	end)

	local ParentNode = FindParentNodeForChoice(CurrentTree, Choice)
	if ParentNode then
		Components.CreateLabel("Parent Response:", EditorScroll, 0.5)
		Components.CreateButton(
			"← " .. ParentNode.Id,
			EditorScroll,
			0.6,
			Constants.COLORS.Primary,
			function()
				OnNavigateToNode(ParentNode)
			end
		)
	end

	Components.CreateLabel("Choice ID:", EditorScroll, 1)
	Components.CreateTextBox(Choice.Id or "choice_unknown", EditorScroll, 2, false, function(NewId)
		Choice.Id = NewId
	end)

	ChoiceEditor.RenderStandalone(Choice, EditorScroll, OnRefresh, OnNavigateToNode, CurrentTree)
end

function EditorPanel.RenderNodeEditor(
	EditorScroll: ScrollingFrame,
	SelectedNode: DialogNode,
	OnRefresh: () -> (),
	_: (DialogNode) -> (),
	OnNavigateToChoice: (DialogChoice) -> (),
	CurrentTree: DialogNode?
)
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
	NodeTypeLabel.Size = UDim2.new(1, -100, 1, 0)
	NodeTypeLabel.Text = "DIALOG/RESPONSE NODE"
	NodeTypeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	NodeTypeLabel.BackgroundTransparency = 1
	NodeTypeLabel.Font = Constants.FONTS.Bold
	NodeTypeLabel.TextSize = 14
	NodeTypeLabel.Parent = NodeTypeFrame

	if SelectedNode.Id ~= "start" then
		local DeleteButton = Instance.new("TextButton")
		DeleteButton.Size = UDim2.fromOffset(80, 28)
		DeleteButton.Position = UDim2.new(1, -90, 0.5, -14)
		DeleteButton.Text = "Delete"
		DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
		DeleteButton.BorderSizePixel = 0
		DeleteButton.Font = Constants.FONTS.Medium
		DeleteButton.TextSize = 12
		DeleteButton.AutoButtonColor = false
		DeleteButton.Parent = NodeTypeFrame

		local DeleteCorner = Instance.new("UICorner")
		DeleteCorner.CornerRadius = UDim.new(0, 4)
		DeleteCorner.Parent = DeleteButton

		DeleteButton.MouseButton1Click:Connect(function()
			Prompt.CreateConfirmation(
				EditorScroll.Parent.Parent.Parent,
				"Delete Response Node",
				"Deleting this response node will set its parent choice to 'End Dialog'. Continue?",
				"Delete",
				function(Confirmed: boolean)
					if Confirmed then
						local function FindAndRemoveNode(Node: DialogNode): boolean
							if Node.Choices then
								for _, Choice in ipairs(Node.Choices) do
									if Choice.ResponseNode == SelectedNode then
										Choice.ResponseNode = nil
										DialogTree.SetResponseType(Choice, DialogTree.RESPONSE_TYPES.END_DIALOG)
										OnRefresh()
										return true
									end

									if Choice.SkillCheck then
										if Choice.SkillCheck.SuccessNode == SelectedNode then
											Choice.SkillCheck.SuccessNode = nil
											return true
										end
										if Choice.SkillCheck.FailureNode == SelectedNode then
											Choice.SkillCheck.FailureNode = nil
											return true
										end

										if Choice.SkillCheck.SuccessNode and FindAndRemoveNode(Choice.SkillCheck.SuccessNode) then
											return true
										end
										if Choice.SkillCheck.FailureNode and FindAndRemoveNode(Choice.SkillCheck.FailureNode) then
											return true
										end
									elseif Choice.ResponseNode and FindAndRemoveNode(Choice.ResponseNode) then
										return true
									end
								end
							end
							return false
						end

						if CurrentTree then
							FindAndRemoveNode(CurrentTree)
						end
					end
				end
			)
		end)
	end

	Components.CreateLabel("Node ID:", EditorScroll, 1)
	Components.CreateTextBox(SelectedNode.Id, EditorScroll, 2, false, function(NewId)
		SelectedNode.Id = NewId
	end)

	local IncomingChoices = FindChoicesPointingToNode(CurrentTree, SelectedNode)
	if #IncomingChoices > 0 then
		Components.CreateLabel("Incoming Choices:", EditorScroll, 2.5)

		local LinksContainer = Instance.new("Frame")
		LinksContainer.Name = "IncomingChoicesContainer"
		LinksContainer.Size = UDim2.new(1, 0, 0, 100)
		LinksContainer.BackgroundTransparency = 1
		LinksContainer.LayoutOrder = 2.6
		LinksContainer.Parent = EditorScroll

		local LinksLayout = Instance.new("UIListLayout")
		LinksLayout.Padding = UDim.new(0, 6)
		LinksLayout.SortOrder = Enum.SortOrder.LayoutOrder
		LinksLayout.Parent = LinksContainer

		for Index, ChoiceLink in ipairs(IncomingChoices) do
			Components.CreateButton(
				"→ " .. (ChoiceLink.Id or "choice") .. ": " .. ChoiceLink.ButtonText:sub(1, 20),
				LinksContainer,
				Index,
				Constants.COLORS.Accent,
				function()
					OnNavigateToChoice(ChoiceLink)
				end
			)
		end

		LinksLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			LinksContainer.Size = UDim2.new(1, 0, 0, LinksLayout.AbsoluteContentSize.Y)
		end)
	end

	Components.CreateLabel("Dialog Text:", EditorScroll, 3)
	Components.CreateTextBox(SelectedNode.Text, EditorScroll, 4, true, function(NewText)
		SelectedNode.Text = NewText
	end)

	local _, GreetingsContent = Components.CreateCollapsibleSection(
		"Greetings",
		EditorScroll,
		3.5,
		false
	)

	if not SelectedNode.Greetings then
		SelectedNode.Greetings = {}
	end

	for Index, Greeting in ipairs(SelectedNode.Greetings) do
		local GreetingFrame = Instance.new("Frame")
		GreetingFrame.Name = "Greeting_" .. tostring(Index)
		GreetingFrame.Size = UDim2.new(1, 0, 0, 220)
		GreetingFrame.BackgroundColor3 = Constants.COLORS.BackgroundDark
		GreetingFrame.BorderSizePixel = 1
		GreetingFrame.BorderColor3 = Constants.COLORS.Border
		GreetingFrame.LayoutOrder = Index
		GreetingFrame.Parent = GreetingsContent

		local GreetingCorner = Instance.new("UICorner")
		GreetingCorner.CornerRadius = UDim.new(0, 6)
		GreetingCorner.Parent = GreetingFrame

		local GreetingLayout = Instance.new("UIListLayout")
		GreetingLayout.Padding = UDim.new(0, 8)
		GreetingLayout.SortOrder = Enum.SortOrder.LayoutOrder
		GreetingLayout.Parent = GreetingFrame

		local GreetingPadding = Instance.new("UIPadding")
		GreetingPadding.PaddingLeft = UDim.new(0, 8)
		GreetingPadding.PaddingRight = UDim.new(0, 8)
		GreetingPadding.PaddingTop = UDim.new(0, 8)
		GreetingPadding.PaddingBottom = UDim.new(0, 8)
		GreetingPadding.Parent = GreetingFrame

		Components.CreateLabel("Condition Type:", GreetingFrame, 1)
		Components.CreateTextBox(Greeting.ConditionType, GreetingFrame, 2, false, function(NewText)
			Greeting.ConditionType = NewText
		end)

		Components.CreateLabel("Condition Value:", GreetingFrame, 3)
		Components.CreateTextBox(Greeting.ConditionValue, GreetingFrame, 4, false, function(NewText)
			Greeting.ConditionValue = NewText
		end)

		Components.CreateLabel("Greeting Text:", GreetingFrame, 5)
		Components.CreateTextBox(Greeting.GreetingText, GreetingFrame, 6, true, function(NewText)
			Greeting.GreetingText = NewText
		end)

		Components.CreateButton("Delete Greeting", GreetingFrame, 7, Constants.COLORS.Danger, function()
			DialogTree.RemoveGreeting(SelectedNode, Index)
			OnRefresh()
		end)
	end

	Components.CreateButton("+ Add Greeting", GreetingsContent, 1000, Constants.COLORS.Accent, function()
		DialogTree.AddGreeting(SelectedNode, "HasQuest", "QuestID", "Greeting text...")
		OnRefresh()
	end)

	Components.CreateLabel("Choices:", EditorScroll, 5)

	if not SelectedNode.Choices then
		SelectedNode.Choices = {}
	end

	local ChoicesContainer = Instance.new("Frame")
	ChoicesContainer.Name = "ChoicesContainer"
	ChoicesContainer.Size = UDim2.new(1, 0, 0, 100)
	ChoicesContainer.BackgroundTransparency = 1
	ChoicesContainer.LayoutOrder = 6
	ChoicesContainer.Parent = EditorScroll

	local ChoicesLayout = Instance.new("UIListLayout")
	ChoicesLayout.Padding = UDim.new(0, 6)
	ChoicesLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ChoicesLayout.Parent = ChoicesContainer

	for Index, ChoiceLink in ipairs(SelectedNode.Choices) do
		local ButtonContainer = Instance.new("Frame")
		ButtonContainer.Size = UDim2.new(1, 0, 0, 32)
		ButtonContainer.BackgroundTransparency = 1
		ButtonContainer.LayoutOrder = Index
		ButtonContainer.Parent = ChoicesContainer

		local ButtonLayout = Instance.new("UIListLayout")
		ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
		ButtonLayout.Padding = UDim.new(0, 6)
		ButtonLayout.Parent = ButtonContainer

		Components.CreateButton(
			"→ " .. (ChoiceLink.Id or "choice"),
			ButtonContainer,
			1,
			Constants.COLORS.Accent,
			function()
				OnNavigateToChoice(ChoiceLink)
			end
		)

		local DeleteChoiceBtn = Instance.new("TextButton")
		DeleteChoiceBtn.Size = UDim2.fromOffset(60, 32)
		DeleteChoiceBtn.Text = "Delete"
		DeleteChoiceBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
		DeleteChoiceBtn.BackgroundColor3 = Constants.COLORS.Danger
		DeleteChoiceBtn.BorderSizePixel = 0
		DeleteChoiceBtn.Font = Constants.FONTS.Medium
		DeleteChoiceBtn.TextSize = 12
		DeleteChoiceBtn.AutoButtonColor = false
		DeleteChoiceBtn.Parent = ButtonContainer

		local DeleteChoiceCorner = Instance.new("UICorner")
		DeleteChoiceCorner.CornerRadius = UDim.new(0, 4)
		DeleteChoiceCorner.Parent = DeleteChoiceBtn

		DeleteChoiceBtn.MouseButton1Click:Connect(function()
			Prompt.CreateConfirmation(
				EditorScroll.Parent.Parent.Parent,
				"Delete Choice",
				"Are you sure you want to delete this choice? This action cannot be undone.",
				"Delete",
				function(Confirmed: boolean)
					if Confirmed then
						DialogTree.RemoveChoice(SelectedNode, Index)
						OnRefresh()
					end
				end
			)
		end)
	end

	ChoicesLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ChoicesContainer.Size = UDim2.new(1, 0, 0, ChoicesLayout.AbsoluteContentSize.Y)
	end)

	Components.CreateButton("+ Add Choice", EditorScroll, 1000, Constants.COLORS.Primary, function()
		DialogTree.AddChoice(SelectedNode, DialogTree.CreateChoice("New choice"))
		OnRefresh()
	end)
end

return EditorPanel