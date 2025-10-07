--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local ConditionEditor = require(script.Parent.ConditionEditor)
local FlagsEditor = require(script.Parent.FlagsEditor)
local CommandEditor = require(script.Parent.CommandEditor)
local Prompt = require(script.Parent.Parent.UI.Prompt)

type DialogChoice = DialogTree.DialogChoice
type DialogNode = DialogTree.DialogNode

local ChoiceEditor = {}

local CHOICE_TYPES = {
	"Simple Choice",
	"Skill Check",
	"Quest Turn-In"
}

local CollapsedStates: {[string]: boolean} = {}
local CurrentTreeForLoopSettings: DialogNode? = nil

local function RecalculateAllChoiceHeights(Parent: Instance)
	task.defer(function()
		for _, Sibling in ipairs(Parent:GetChildren()) do
			if Sibling:IsA("Frame") and Sibling.Name:match("^Choice_") then
				local Content = Sibling:FindFirstChild("Content")
				local Layout = Sibling:FindFirstChildOfClass("UIListLayout")
				if Content and Layout then
					local IsCollapsed = not Content.Visible
					local NewHeight = IsCollapsed and 56 or Layout.AbsoluteContentSize.Y + 32
					Sibling.Size = UDim2.new(1, 0, 0, NewHeight)
				end
			end
		end

		local Layout = Parent:FindFirstChildOfClass("UIListLayout")
		if Layout then
			Parent.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
		end
	end)
end

local function RefreshChoiceContent(
	Choice: DialogChoice,
	ContentFrame: Frame,
	OnNavigate: (DialogNode) -> (),
	OnRefresh: () -> ()
)
	for _, Child in ipairs(ContentFrame:GetChildren()) do
		if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
			Child:Destroy()
		end
	end

	Components.CreateLabel("Button Text", ContentFrame, 1)
	Components.CreateTextBox(Choice.ButtonText, ContentFrame, 2, false, function(NewText: string)
		Choice.ButtonText = NewText
	end)

	-- RESPONSE TYPE SELECTOR
	if not Choice.ResponseType then
		Choice.ResponseType = DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE
	end

	Components.CreateLabel("Response Type", ContentFrame, 3)
	Components.CreateDropdown(
		{"Default Response", "Return to Start", "Return to Node", "End Dialog"},
		Choice.ResponseType == DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE and "Default Response" or
		Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START and "Return to Start" or
		Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE and "Return to Node" or
		"End Dialog",
		ContentFrame,
		4,
		function(Selected: string)
			if Selected == "Default Response" then
				DialogTree.SetResponseType(Choice, DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE)
			elseif Selected == "Return to Start" then
				DialogTree.SetResponseType(Choice, DialogTree.RESPONSE_TYPES.RETURN_TO_START)
			elseif Selected == "Return to Node" then
				DialogTree.SetResponseType(Choice, DialogTree.RESPONSE_TYPES.RETURN_TO_NODE)
				if not Choice.ReturnToNodeId and CurrentTreeForLoopSettings then
					local AllNodeIds = DialogTree.GetAllNodeIds(CurrentTreeForLoopSettings)
					Choice.ReturnToNodeId = AllNodeIds[1] or "start"
				end
			else
				DialogTree.SetResponseType(Choice, DialogTree.RESPONSE_TYPES.END_DIALOG)
			end
			OnRefresh()
		end
	)

	-- SHOW RESPONSE FIELDS IF DEFAULT RESPONSE
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
		if Choice.ResponseNode then
			Components.CreateLabel("Response Text Preview", ContentFrame, 5)
			local PreviewLabel = Instance.new("TextLabel")
			PreviewLabel.Size = UDim2.new(1, 0, 0, 40)
			PreviewLabel.Text = Choice.ResponseNode.Text:sub(1, 60) .. (Choice.ResponseNode.Text:len() > 60 and "..." or "")
			PreviewLabel.TextColor3 = Constants.COLORS.TextSecondary
			PreviewLabel.BackgroundColor3 = Constants.COLORS.BackgroundDark
			PreviewLabel.BorderSizePixel = 1
			PreviewLabel.BorderColor3 = Constants.COLORS.Border
			PreviewLabel.Font = Constants.FONTS.Regular
			PreviewLabel.TextSize = 12
			PreviewLabel.TextWrapped = true
			PreviewLabel.TextXAlignment = Enum.TextXAlignment.Left
			PreviewLabel.TextYAlignment = Enum.TextYAlignment.Top
			PreviewLabel.LayoutOrder = 6
			PreviewLabel.Parent = ContentFrame

			local PreviewPadding = Instance.new("UIPadding")
			PreviewPadding.PaddingLeft = UDim.new(0, 8)
			PreviewPadding.PaddingTop = UDim.new(0, 8)
			PreviewPadding.Parent = PreviewLabel

			Components.CreateButton("Edit Response Node →", ContentFrame, 7, Constants.COLORS.Primary, function()
				OnNavigate(Choice.ResponseNode)
			end)
		end
	elseif Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		-- SHOW NODE SELECTOR
		if CurrentTreeForLoopSettings then
			local AllNodeIds = DialogTree.GetAllNodeIds(CurrentTreeForLoopSettings)

			Components.CreateLabel("Target Node", ContentFrame, 5)

			local InputFrame = Instance.new("Frame")
			InputFrame.Size = UDim2.new(1, 0, 0, 35)
			InputFrame.BackgroundTransparency = 1
			InputFrame.LayoutOrder = 6
			InputFrame.Parent = ContentFrame

			local InputLayout = Instance.new("UIListLayout")
			InputLayout.FillDirection = Enum.FillDirection.Horizontal
			InputLayout.Padding = UDim.new(0, 5)
			InputLayout.Parent = InputFrame

			local DropdownContainer = Instance.new("Frame")
			DropdownContainer.Size = UDim2.fromScale(0.6, 1)
			DropdownContainer.BackgroundTransparency = 1
			DropdownContainer.Parent = InputFrame

			Components.CreateDropdown(
				AllNodeIds,
				Choice.ReturnToNodeId or (AllNodeIds[1] or "start"),
				DropdownContainer,
				1,
				function(Selected: string)
					DialogTree.SetReturnToNode(Choice, Selected)
				end
			)

			local TextBoxContainer = Instance.new("Frame")
			TextBoxContainer.Size = UDim2.new(0.4, -5, 1, 0)
			TextBoxContainer.BackgroundTransparency = 1
			TextBoxContainer.Parent = InputFrame

			Components.CreateTextBox(Choice.ReturnToNodeId or "", TextBoxContainer, 1, false, function(NewText)
				DialogTree.SetReturnToNode(Choice, NewText ~= "" and NewText or nil)
			end)
		end
	end

	-- SKILL CHECK OR QUEST TURN-IN SPECIFIC FIELDS
	if Choice.SkillCheck then
		ChoiceEditor.RenderSkillCheckFields(Choice, ContentFrame, 10, OnNavigate)
	elseif Choice.QuestTurnIn then
		ChoiceEditor.RenderQuestTurnInFields(Choice, ContentFrame, 10)
	end

	-- CHOICE TYPE SELECTOR (for skill checks, etc)
	local CurrentChoiceType = "Simple Choice"
	if Choice.SkillCheck then
		CurrentChoiceType = "Skill Check"
	elseif Choice.QuestTurnIn then
		CurrentChoiceType = "Quest Turn-In"
	end

	Components.CreateLabel("Choice Type", ContentFrame, 50)
	Components.CreateDropdown(
		CHOICE_TYPES,
		CurrentChoiceType,
		ContentFrame,
		51,
		function(NewType: string)
			if NewType == "Skill Check" then
				DialogTree.ConvertToSkillCheck(Choice, "Perception", 10)
			elseif NewType == "Quest Turn-In" then
				DialogTree.ConvertToQuestTurnIn(Choice, "QuestID")
			else
				DialogTree.ConvertToSimpleChoice(Choice)
			end
			OnRefresh()
		end
	)

	-- CONDITIONS (when this choice appears)
	local _, ConditionsContent = Components.CreateCollapsibleSection(
		"Conditions (When Choice Appears)",
		ContentFrame,
		100,
		true
	)
	ConditionEditor.Render(Choice, ConditionsContent, 1, OnRefresh)

	-- SET FLAGS (when choice is clicked)
	local _, FlagsContent = Components.CreateCollapsibleSection(
		"Set Flags (On Click)",
		ContentFrame,
		101,
		true
	)
	FlagsEditor.Render(Choice, FlagsContent, 1, OnRefresh)

	-- COMMANDS (when choice is clicked)
	local _, CommandContent = Components.CreateCollapsibleSection(
		"Commands (On Click)",
		ContentFrame,
		102,
		true
	)
	CommandEditor.Render(Choice, CommandContent, 1)
end

function ChoiceEditor.Render(
	Choice: DialogChoice,
	Index: number,
	Parent: Instance,
	Order: number,
	OnDelete: () -> (),
	OnNavigate: (DialogNode) -> (),
	OnRefresh: () -> ()
): Frame
	local ChoiceKey = tostring(Parent) .. "_Choice_" .. tostring(Index)
	local IsCollapsed = CollapsedStates[ChoiceKey] or false

	local Container = Instance.new("Frame")
	Container.Name = "Choice_" .. tostring(Index)
	Container.Size = UDim2.new(1, 0, 0, 56)
	Container.BackgroundColor3 = Constants.COLORS.BackgroundLight
	Container.BorderSizePixel = 1
	Container.BorderColor3 = Constants.COLORS.Border
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Container

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 8)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingRight = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingTop = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingBottom = UDim.new(0, Constants.SIZES.Padding)
	Padding.Parent = Container

	local Header = Instance.new("Frame")
	Header.Name = "Header"
	Header.Size = UDim2.new(1, 0, 0, 32)
	Header.BackgroundTransparency = 1
	Header.LayoutOrder = 1
	Header.Parent = Container

	local CollapseButton = Instance.new("TextButton")
	CollapseButton.Size = UDim2.fromOffset(20, 20)
	CollapseButton.Position = UDim2.fromOffset(0, 6)
	CollapseButton.Text = IsCollapsed and "▶" or "▼"
	CollapseButton.TextColor3 = Constants.COLORS.TextPrimary
	CollapseButton.BackgroundTransparency = 1
	CollapseButton.Font = Constants.FONTS.Bold
	CollapseButton.TextSize = 12
	CollapseButton.AutoButtonColor = false
	CollapseButton.Parent = Header

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -100, 1, 0)
	Title.Position = UDim2.fromOffset(28, 0)
	Title.Text = "Choice " .. tostring(Index) .. ": " .. Choice.ButtonText
	Title.TextColor3 = Constants.COLORS.TextPrimary
	Title.BackgroundTransparency = 1
	Title.Font = Constants.FONTS.Medium
	Title.TextSize = 14
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.TextTruncate = Enum.TextTruncate.AtEnd
	Title.Parent = Header

	local DeleteButton = Instance.new("TextButton")
	DeleteButton.Size = UDim2.fromOffset(60, 28)
	DeleteButton.Position = UDim2.new(1, -60, 0, 2)
	DeleteButton.AnchorPoint = Vector2.new(0, 0)
	DeleteButton.Text = "Delete"
	DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
	DeleteButton.BorderSizePixel = 0
	DeleteButton.Font = Constants.FONTS.Medium
	DeleteButton.TextSize = 12
	DeleteButton.AutoButtonColor = false
	DeleteButton.Parent = Header

	local DeleteCorner = Instance.new("UICorner")
	DeleteCorner.CornerRadius = UDim.new(0, 4)
	DeleteCorner.Parent = DeleteButton

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "Content"
	ContentFrame.Size = UDim2.new(1, 0, 0, 100)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.LayoutOrder = 2
	ContentFrame.Visible = not IsCollapsed
	ContentFrame.Parent = Container

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, 8)
	ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentLayout.Parent = ContentFrame

	RefreshChoiceContent(Choice, ContentFrame, OnNavigate, OnRefresh)

	CollapseButton.MouseButton1Click:Connect(function()
		IsCollapsed = not IsCollapsed
		CollapsedStates[ChoiceKey] = IsCollapsed
		CollapseButton.Text = IsCollapsed and "▶" or "▼"
		ContentFrame.Visible = not IsCollapsed
		RecalculateAllChoiceHeights(Parent)
	end)

	DeleteButton.MouseButton1Click:Connect(function()
		Prompt.CreateConfirmation(
			script.Parent.Parent.Parent.Parent.Parent.Parent,
			"Delete Choice",
			"Are you sure you want to delete this choice? This action cannot be undone.",
			"Delete",
			function(Confirmed: boolean)
				if Confirmed then
					OnDelete()
				end
			end
		)
	end)

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if not IsCollapsed then
			Container.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + Constants.SIZES.Padding * 2)
		end
	end)

	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ContentFrame.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y)
		if not IsCollapsed then
			Container.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + Constants.SIZES.Padding * 2)
		end
	end)

	return Container
end

function ChoiceEditor.RenderSkillCheckFields(
	Choice: DialogChoice,
	Parent: Frame,
	StartOrder: number,
	OnNavigate: (DialogNode) -> ()
)
	if not Choice.SkillCheck then
		return
	end

	Components.CreateLabel("Skill Type", Parent, StartOrder)
	Components.CreateTextBox(Choice.SkillCheck.Skill or "Perception", Parent, StartOrder + 1, false, function(NewSkill: string)
		Choice.SkillCheck.Skill = NewSkill
	end)

	Components.CreateLabel("Difficulty", Parent, StartOrder + 2)
	Components.CreateTextBox(tostring(Choice.SkillCheck.Difficulty or 10), Parent, StartOrder + 3, false, function(NewDiff: string)
		local DiffNum = tonumber(NewDiff)
		if DiffNum then
			Choice.SkillCheck.Difficulty = DiffNum
		end
	end)

	if Choice.SkillCheck.SuccessNode then
		Components.CreateButton("Edit Success Branch →", Parent, StartOrder + 4, Constants.COLORS.Success, function()
			OnNavigate(Choice.SkillCheck.SuccessNode)
		end)
	end

	if Choice.SkillCheck.FailureNode then
		Components.CreateButton("Edit Failure Branch →", Parent, StartOrder + 5, Constants.COLORS.Danger, function()
			OnNavigate(Choice.SkillCheck.FailureNode)
		end)
	end
end

function ChoiceEditor.RenderQuestTurnInFields(
	Choice: DialogChoice,
	Parent: Frame,
	StartOrder: number
)
	if not Choice.QuestTurnIn then
		return
	end

	Components.CreateLabel("Quest ID", Parent, StartOrder)
	Components.CreateTextBox(Choice.QuestTurnIn.QuestId or "QuestID", Parent, StartOrder + 1, false, function(NewId: string)
		Choice.QuestTurnIn.QuestId = NewId
	end)

	Components.CreateLabel("Success Text", Parent, StartOrder + 2)
	Components.CreateTextBox(Choice.QuestTurnIn.ResponseText or "Quest complete!", Parent, StartOrder + 3, true, function(NewText: string)
		Choice.QuestTurnIn.ResponseText = NewText
	end)
end

function ChoiceEditor.SetCurrentTree(Tree: DialogNode?)
	CurrentTreeForLoopSettings = Tree
end

return ChoiceEditor