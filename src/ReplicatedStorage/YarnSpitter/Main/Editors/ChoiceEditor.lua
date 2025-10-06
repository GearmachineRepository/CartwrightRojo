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

local function RecalculateAllChoiceHeights(Parent: Instance)
	task.defer(function()
		for _, sibling in ipairs(Parent:GetChildren()) do
			if sibling:IsA("Frame") and sibling.Name:match("^Choice_") then
				local content = sibling:FindFirstChild("Content")
				local layout = sibling:FindFirstChildOfClass("UIListLayout")
				if content and layout then
					local isCollapsed = not content.Visible
					local newHeight = isCollapsed and 56 or layout.AbsoluteContentSize.Y + 32
					sibling.Size = UDim2.new(1, 0, 0, newHeight)
				end
			end
		end

		local layout = Parent:FindFirstChildOfClass("UIListLayout")
		if layout then
			Parent.Size = UDim2.new(1, 0, 0, layout.AbsoluteContentSize.Y)
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

	if Choice.ResponseNode then
		Components.CreateLabel("Response Text", ContentFrame, 3)
		Components.CreateTextBox(Choice.ResponseNode.Text, ContentFrame, 4, true, function(NewText: string)
			Choice.ResponseNode.Text = NewText
		end)
	end

	if Choice.SkillCheck then
		ChoiceEditor.RenderSkillCheckFields(Choice, ContentFrame, 10, OnNavigate)
	elseif Choice.QuestTurnIn then
		ChoiceEditor.RenderQuestTurnInFields(Choice, ContentFrame, 10)
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
			NavigateButton.LayoutOrder = 10
			NavigateButton.Parent = ContentFrame

			local NavCorner = Instance.new("UICorner")
			NavCorner.CornerRadius = UDim.new(0, 6)
			NavCorner.Parent = NavigateButton

			NavigateButton.MouseButton1Click:Connect(function()
				OnNavigate(Choice.ResponseNode)
			end)
		end
	end

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

	local _, ConditionsContent = Components.CreateCollapsibleSection(
		"Conditions",
		ContentFrame,
		100,
		true
	)
	ConditionEditor.Render(Choice, ConditionsContent, 1, OnRefresh)

	local _, FlagsContent = Components.CreateCollapsibleSection(
		"Set Flags",
		ContentFrame,
		101,
		true
	)
	FlagsEditor.Render(Choice, FlagsContent, 1, OnRefresh)

	local _, CommandContent = Components.CreateCollapsibleSection(
		"Commands",
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
	Container.Name = string.format("Choice_%03d", Index)
	Container.Size = UDim2.new(1, 0, 0, 200)
	Container.BackgroundColor3 = Constants.COLORS.BackgroundLight
	Container.BorderSizePixel = 1
	Container.BorderColor3 = Constants.COLORS.Border
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
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

	local HeaderFrame = Instance.new("Frame")
	HeaderFrame.Size = UDim2.new(1, 0, 0, 30)
	HeaderFrame.BackgroundTransparency = 1
	HeaderFrame.LayoutOrder = 0
	HeaderFrame.Parent = Container

	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.fromOffset(24, 24)
	ToggleButton.Position = UDim2.fromOffset(0, 3)
	ToggleButton.Text = IsCollapsed and "▶" or "▼"
	ToggleButton.TextColor3 = Constants.COLORS.TextSecondary
	ToggleButton.BackgroundTransparency = 1
	ToggleButton.Font = Constants.FONTS.Regular
	ToggleButton.TextSize = 14
	ToggleButton.Parent = HeaderFrame

	local HeaderLabel = Instance.new("TextLabel")
	HeaderLabel.Size = UDim2.new(1, -100, 1, 0)
	HeaderLabel.Position = UDim2.fromOffset(28, 0)
	HeaderLabel.Text = string.format("Choice %d: %s", Index, Choice.ButtonText:sub(1, 30))
	HeaderLabel.TextColor3 = Constants.COLORS.TextPrimary
	HeaderLabel.BackgroundTransparency = 1
	HeaderLabel.Font = Constants.FONTS.Bold
	HeaderLabel.TextSize = Constants.TEXT_SIZES.Normal
	HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
	HeaderLabel.Parent = HeaderFrame

	local DeleteButton = Instance.new("TextButton")
	DeleteButton.Size = UDim2.fromOffset(60, 24)
	DeleteButton.Position = UDim2.new(1, -60, 0, 3)
	DeleteButton.Text = "Delete"
	DeleteButton.TextColor3 = Constants.COLORS.TextPrimary
	DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
	DeleteButton.BorderSizePixel = 0
	DeleteButton.Font = Constants.FONTS.Medium
	DeleteButton.TextSize = 12
	DeleteButton.AutoButtonColor = false
	DeleteButton.Parent = HeaderFrame

	local DeleteCorner = Instance.new("UICorner")
	DeleteCorner.CornerRadius = UDim.new(0, 4)
	DeleteCorner.Parent = DeleteButton

	DeleteButton.MouseButton1Click:Connect(OnDelete)

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "Content"
	ContentFrame.Size = UDim2.new(1, 0, 0, 100)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.LayoutOrder = 1
	ContentFrame.Visible = not IsCollapsed
	ContentFrame.Parent = Container

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, 8)
	ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentLayout.Parent = ContentFrame

	local ContentPadding = Instance.new("UIPadding")
	ContentPadding.PaddingLeft = UDim.new(0, 4)
	ContentPadding.Parent = ContentFrame

	local function UpdateCollapsedState()
		IsCollapsed = not IsCollapsed
		CollapsedStates[ChoiceKey] = IsCollapsed

		ToggleButton.Text = IsCollapsed and "▶" or "▼"
		HeaderLabel.Text = string.format("Choice %d%s", Index, IsCollapsed and ": " .. Choice.ButtonText:sub(1, 30) or "")
		ContentFrame.Visible = not IsCollapsed

		-- Force re-layout of siblings
		task.defer(function()
			for _, sibling in ipairs(Parent:GetChildren()) do
				if sibling:IsA("Frame") and sibling.Name:match("^Choice_") then
					local content = sibling:FindFirstChild("Content")
					local layout = sibling:FindFirstChildOfClass("UIListLayout")
					if content and layout then
						local isCollapsed = not content.Visible
						local newHeight = isCollapsed and 56 or layout.AbsoluteContentSize.Y + 32
						sibling.Size = UDim2.new(1, 0, 0, newHeight)
					end
				end
			end

			local parentLayout = Parent:FindFirstChildOfClass("UIListLayout")
			if parentLayout then
				Parent.Size = UDim2.new(1, 0, 0, parentLayout.AbsoluteContentSize.Y)
			end
		end)
	end

	ToggleButton.MouseButton1Click:Connect(UpdateCollapsedState)

	RefreshChoiceContent(Choice, ContentFrame, OnNavigate, OnRefresh)
	RecalculateAllChoiceHeights(Parent)

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
	Components.CreateTextBox(Choice.SkillCheck.SkillType or "Perception", Parent, StartOrder + 1, false, function(NewSkill: string)
		Choice.SkillCheck.SkillType = NewSkill
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
	Components.CreateTextBox(Choice.QuestTurnIn.SuccessText or "Quest complete!", Parent, StartOrder + 3, true, function(NewText: string)
		Choice.QuestTurnIn.SuccessText = NewText
	end)

	Components.CreateLabel("Failure Text", Parent, StartOrder + 4)
	Components.CreateTextBox(Choice.QuestTurnIn.FailureText or "Quest incomplete.", Parent, StartOrder + 5, true, function(NewText: string)
		Choice.QuestTurnIn.FailureText = NewText
	end)
end

return ChoiceEditor