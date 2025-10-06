--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local ConditionEditor = require(script.Parent.ConditionEditor)
local FlagsEditor = require(script.Parent.FlagsEditor)
local CommandEditor = require(script.Parent.CommandEditor)

type DialogChoice = DialogTree.DialogChoice
type DialogNode = DialogTree.DialogNode

local ChoiceEditor = {}

local CHOICE_TYPES = {
	"Simple Choice",
	"Skill Check",
	"Quest Turn-In"
}

local CollapsedStates: {[string]: boolean} = {}

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
	Container.Name = string.format("Choice_%03d", Index)
	Container.Size = UDim2.new(1, 0, 0, 200)
	Container.BackgroundColor3 = Constants.COLORS.BackgroundLight
	Container.BorderSizePixel = 1
	Container.BorderColor3 = Constants.COLORS.Border
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Container

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 12)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 16)
	Padding.PaddingRight = UDim.new(0, 16)
	Padding.PaddingTop = UDim.new(0, 16)
	Padding.PaddingBottom = UDim.new(0, 16)
	Padding.Parent = Container

	local HeaderRow = Instance.new("Frame")
	HeaderRow.Size = UDim2.new(1, 0, 0, 24)
	HeaderRow.BackgroundTransparency = 1
	HeaderRow.LayoutOrder = 1
	HeaderRow.Parent = Container

	local CollapseButton = Instance.new("TextButton")
	CollapseButton.Size = UDim2.fromOffset(20, 24)
	CollapseButton.Position = UDim2.fromOffset(0, 0)
	CollapseButton.Text = IsCollapsed and "▶" or "▼"
	CollapseButton.TextColor3 = Constants.COLORS.TextSecondary
	CollapseButton.BackgroundTransparency = 1
	CollapseButton.Font = Constants.FONTS.Regular
	CollapseButton.TextSize = 12
	CollapseButton.AutoButtonColor = false
	CollapseButton.Parent = HeaderRow

	local HeaderLabel = Instance.new("TextLabel")
	HeaderLabel.Size = UDim2.new(1, -95, 1, 0)
	HeaderLabel.Position = UDim2.fromOffset(25, 0)
	HeaderLabel.Text = "Choice " .. tostring(Index) .. (IsCollapsed and ": " .. Choice.ButtonText:sub(1, 30) or "")
	HeaderLabel.TextColor3 = Constants.COLORS.TextSecondary
	HeaderLabel.BackgroundTransparency = 1
	HeaderLabel.Font = Constants.FONTS.Bold
	HeaderLabel.TextSize = 14
	HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
	HeaderLabel.TextTruncate = Enum.TextTruncate.AtEnd
	HeaderLabel.Parent = HeaderRow

	local DeleteButton = Instance.new("TextButton")
	DeleteButton.Size = UDim2.fromOffset(60, 24)
	DeleteButton.Position = UDim2.new(1, -60, 0, 0)
	DeleteButton.Text = "Delete"
	DeleteButton.TextColor3 = Constants.COLORS.Danger
	DeleteButton.BackgroundTransparency = 1
	DeleteButton.Font = Constants.FONTS.Medium
	DeleteButton.TextSize = 12
	DeleteButton.BorderSizePixel = 0
	DeleteButton.AutoButtonColor = false
	DeleteButton.Parent = HeaderRow

	DeleteButton.MouseButton1Click:Connect(OnDelete)

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "ContentFrame"
	ContentFrame.Size = UDim2.new(1, 0, 0, 100)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.LayoutOrder = 2
	ContentFrame.Visible = not IsCollapsed
	ContentFrame.Parent = Container

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, 12)
	ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentLayout.Parent = ContentFrame

	local function UpdateCollapsedState()
		IsCollapsed = not IsCollapsed
		CollapsedStates[ChoiceKey] = IsCollapsed

		CollapseButton.Text = IsCollapsed and "▶" or "▼"
		HeaderLabel.Text = "Choice " .. tostring(Index) .. (IsCollapsed and ": " .. Choice.ButtonText:sub(1, 30) or "")
		ContentFrame.Visible = not IsCollapsed

		local TargetHeight = IsCollapsed and 56 or (Layout.AbsoluteContentSize.Y + 32)
		Container.Size = UDim2.new(1, 0, 0, TargetHeight)
	end

	CollapseButton.MouseButton1Click:Connect(UpdateCollapsedState)

	Components.CreateLabel("Button Text", ContentFrame, 2)
	Components.CreateTextBox(Choice.ButtonText, ContentFrame, 3, false, function(NewText: string)
		Choice.ButtonText = NewText
		if IsCollapsed then
			HeaderLabel.Text = "Choice " .. tostring(Index) .. ": " .. NewText:sub(1, 30)
		end
		OnRefresh()
	end)

	if Choice.ResponseNode then
		Components.CreateLabel("Response Text", ContentFrame, 4)
		Components.CreateTextBox(Choice.ResponseNode.Text, ContentFrame, 5, true, function(NewText: string)
			Choice.ResponseNode.Text = NewText
			OnRefresh()
		end)
	end

	local CurrentChoiceType = "Simple Choice"
	if Choice.SkillCheck then
		CurrentChoiceType = "Skill Check"
	elseif Choice.QuestTurnIn then
		CurrentChoiceType = "Quest Turn-In"
	end

	Components.CreateLabel("Choice Type", ContentFrame, 6)
	Components.CreateDropdown(
		CHOICE_TYPES,
		CurrentChoiceType,
		ContentFrame,
		7,
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

	if Choice.SkillCheck then
		ChoiceEditor.RenderSkillCheckFields(Choice, ContentFrame, 8, OnNavigate)
	elseif Choice.QuestTurnIn then
		ChoiceEditor.RenderQuestTurnInFields(Choice, ContentFrame, 8)
	else
		if Choice.ResponseNode then
			local NavigateButton = Instance.new("TextButton")
			NavigateButton.Size = UDim2.new(1, 0, 0, 36)
			NavigateButton.Text = "Edit Response Branch →"
			NavigateButton.TextColor3 = Constants.COLORS.Primary
			NavigateButton.BackgroundColor3 = Constants.COLORS.BackgroundLight
			NavigateButton.BorderSizePixel = 1
			NavigateButton.BorderColor3 = Constants.COLORS.Border
			NavigateButton.Font = Constants.FONTS.Medium
			NavigateButton.TextSize = 14
			NavigateButton.AutoButtonColor = false
			NavigateButton.LayoutOrder = 8
			NavigateButton.Parent = ContentFrame

			local NavCorner = Instance.new("UICorner")
			NavCorner.CornerRadius = UDim.new(0, 6)
			NavCorner.Parent = NavigateButton

			NavigateButton.MouseButton1Click:Connect(function()
				OnNavigate(Choice.ResponseNode)
			end)
		end
	end

	local _, ConditionsContent = Components.CreateCollapsibleSection(
		"Conditions",
		ContentFrame,
		9,
		true
	)
	ConditionEditor.Render(Choice, ConditionsContent, 1, OnRefresh)

	local _, FlagsContent = Components.CreateCollapsibleSection(
		"Set Flags",
		ContentFrame,
		10,
		true
	)
	FlagsEditor.Render(Choice, FlagsContent, 1, OnRefresh)

	local _, CommandContent = Components.CreateCollapsibleSection(
		"Commands",
		ContentFrame,
		11,
		true
	)
	CommandEditor.Render(Choice, CommandContent, 1)

	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if not IsCollapsed then
			ContentFrame.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y)
			Container.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 32)
		end
	end)

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		if not IsCollapsed then
			Container.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 32)
		end
	end)

	return Container
end

function ChoiceEditor.RenderSkillCheckFields(Choice: DialogChoice, Parent: Frame, StartOrder: number, OnNavigate: (DialogNode) -> ())
	if not Choice.SkillCheck then
		return
	end

	Components.CreateLabel("Skill", Parent, StartOrder)
	Components.CreateDropdown(
		Constants.SKILLS,
		Choice.SkillCheck.Skill,
		Parent,
		StartOrder + 1,
		function(NewSkill: string)
			Choice.SkillCheck.Skill = NewSkill
		end
	)

	Components.CreateLabel("Difficulty", Parent, StartOrder + 2)
	Components.CreateNumberInput(
		Choice.SkillCheck.Difficulty,
		Parent,
		StartOrder + 3,
		function(NewDifficulty: number)
			Choice.SkillCheck.Difficulty = NewDifficulty
		end
	)

	if Choice.SkillCheck.SuccessNode then
		Components.CreateLabel("✓ Success Response", Parent, StartOrder + 4)
		Components.CreateTextBox(
			Choice.SkillCheck.SuccessNode.Text,
			Parent,
			StartOrder + 5,
			true,
			function(NewText: string)
				Choice.SkillCheck.SuccessNode.Text = NewText
			end
		)
	end

	if Choice.SkillCheck.FailureNode then
		Components.CreateLabel("✗ Failure Response", Parent, StartOrder + 6)
		Components.CreateTextBox(
			Choice.SkillCheck.FailureNode.Text,
			Parent,
			StartOrder + 7,
			true,
			function(NewText: string)
				Choice.SkillCheck.FailureNode.Text = NewText
			end
		)
	end

	if Choice.SkillCheck.SuccessNode and Choice.SkillCheck.FailureNode then
		local ButtonRow = Instance.new("Frame")
		ButtonRow.Size = UDim2.new(1, 0, 0, 36)
		ButtonRow.BackgroundTransparency = 1
		ButtonRow.LayoutOrder = StartOrder + 8
		ButtonRow.Parent = Parent

		local ButtonLayout = Instance.new("UIListLayout")
		ButtonLayout.FillDirection = Enum.FillDirection.Horizontal
		ButtonLayout.Padding = UDim.new(0, 8)
		ButtonLayout.Parent = ButtonRow

		local SuccessButton = Instance.new("TextButton")
		SuccessButton.Size = UDim2.new(0.5, -4, 1, 0)
		SuccessButton.Text = "→ Success Branch"
		SuccessButton.TextColor3 = Constants.COLORS.Success
		SuccessButton.BackgroundColor3 = Constants.COLORS.BackgroundLight
		SuccessButton.BorderSizePixel = 1
		SuccessButton.BorderColor3 = Constants.COLORS.Border
		SuccessButton.Font = Constants.FONTS.Medium
		SuccessButton.TextSize = 14
		SuccessButton.AutoButtonColor = false
		SuccessButton.Parent = ButtonRow

		local SuccessCorner = Instance.new("UICorner")
		SuccessCorner.CornerRadius = UDim.new(0, 6)
		SuccessCorner.Parent = SuccessButton

		local FailureButton = Instance.new("TextButton")
		FailureButton.Size = UDim2.new(0.5, -4, 1, 0)
		FailureButton.Text = "→ Failure Branch"
		FailureButton.TextColor3 = Constants.COLORS.Danger
		FailureButton.BackgroundColor3 = Constants.COLORS.BackgroundLight
		FailureButton.BorderSizePixel = 1
		FailureButton.BorderColor3 = Constants.COLORS.Border
		FailureButton.Font = Constants.FONTS.Medium
		FailureButton.TextSize = 14
		FailureButton.AutoButtonColor = false
		FailureButton.Parent = ButtonRow

		local FailureCorner = Instance.new("UICorner")
		FailureCorner.CornerRadius = UDim.new(0, 6)
		FailureCorner.Parent = FailureButton

		SuccessButton.MouseButton1Click:Connect(function()
			OnNavigate(Choice.SkillCheck.SuccessNode)
		end)

		FailureButton.MouseButton1Click:Connect(function()
			OnNavigate(Choice.SkillCheck.FailureNode)
		end)
	end
end

function ChoiceEditor.RenderQuestTurnInFields(Choice: DialogChoice, Parent: Frame, StartOrder: number)
	if not Choice.QuestTurnIn then
		return
	end

	Components.CreateLabel("Quest ID", Parent, StartOrder)
	Components.CreateTextBox(
		Choice.QuestTurnIn.QuestId,
		Parent,
		StartOrder + 1,
		false,
		function(NewQuestId: string)
			Choice.QuestTurnIn.QuestId = NewQuestId
		end
	)

	Components.CreateLabel("Success Response", Parent, StartOrder + 2)
	Components.CreateTextBox(
		Choice.QuestTurnIn.ResponseText,
		Parent,
		StartOrder + 3,
		true,
		function(NewText: string)
			Choice.QuestTurnIn.ResponseText = NewText
		end
	)
end

return ChoiceEditor