--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local ConditionEditor = require(script.Parent.ConditionEditor)
local FlagsEditor = require(script.Parent.FlagsEditor)
local CommandEditor = require(script.Parent.CommandEditor)
local Prompt = require(script.Parent.Parent.UI.Prompt)
local TweenService = game:GetService("TweenService")

type DialogChoice = DialogTree.DialogChoice
type DialogNode = DialogTree.DialogNode

local ChoiceEditor = {}

local CHOICE_TYPES = {
	"Simple Choice",
	"Skill Check",
	"Quest Turn-In"
}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
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

	if not Choice.ResponseType then
		Choice.ResponseType = DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE
	end

	if not Choice.SkillCheck and not Choice.QuestTurnIn then
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

				-- Create underlined link instead of button
				local LinkButton = Instance.new("TextButton")
				LinkButton.Size = UDim2.new(1, 0, 0, 28)
				LinkButton.BackgroundTransparency = 1
				LinkButton.AutoButtonColor = false
				LinkButton.RichText = true
				LinkButton.Text = "<u>Edit Response Node →</u>"
				LinkButton.TextColor3 = Constants.COLORS.Primary
				LinkButton.Font = Constants.FONTS.Regular
				LinkButton.TextSize = 14
				LinkButton.TextXAlignment = Enum.TextXAlignment.Left
				LinkButton.LayoutOrder = 7
				LinkButton.Parent = ContentFrame

				LinkButton.MouseEnter:Connect(function()
					LinkButton.TextColor3 = Constants.COLORS.PrimaryHover
				end)

				LinkButton.MouseLeave:Connect(function()
					LinkButton.TextColor3 = Constants.COLORS.Primary
				end)

				LinkButton.MouseButton1Click:Connect(function()
					OnNavigate(Choice.ResponseNode)
				end)
			end
		elseif Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
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
	end

	if Choice.SkillCheck then
		ChoiceEditor.RenderSkillCheckFields(Choice, ContentFrame, 10, OnNavigate)
	elseif Choice.QuestTurnIn then
		ChoiceEditor.RenderQuestTurnInFields(Choice, ContentFrame, 10)
	end

	if not Choice.SkillCheck and not Choice.QuestTurnIn then
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
	end

	local _, ConditionsContent = Components.CreateCollapsibleSection(
		"Conditions (When Choice Appears)",
		ContentFrame,
		100,
		true
	)
	ConditionEditor.Render(Choice, ConditionsContent, 1, OnRefresh)

	local _, FlagsContent = Components.CreateCollapsibleSection(
		"Set Flags (On Click)",
		ContentFrame,
		101,
		true
	)
	FlagsEditor.Render(Choice, FlagsContent, 1, OnRefresh)

	local _, CommandContent = Components.CreateCollapsibleSection(
		"Commands (On Click)",
		ContentFrame,
		102,
		true
	)
	CommandEditor.Render(Choice, CommandContent, 1)
end

function ChoiceEditor.RenderStandalone(
	Choice: DialogChoice,
	Parent: Frame,
	OnRefresh: () -> (),
	OnNavigateToNode: (DialogNode) -> (),
	CurrentTree: DialogNode?
)
	ChoiceEditor.SetCurrentTree(CurrentTree)

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "StandaloneContent"
	ContentFrame.Size = UDim2.new(1, 0, 0, 100)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.LayoutOrder = 3
	ContentFrame.Parent = Parent

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, 8)
	ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentLayout.Parent = ContentFrame

	RefreshChoiceContent(Choice, ContentFrame, OnNavigateToNode, OnRefresh)

	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ContentFrame.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y)
	end)
end

function ChoiceEditor.Render(
	Choice: DialogChoice,
	Index: number,
	Parent: Frame,
	Order: number,
	OnDelete: () -> (),
	OnNavigateToNode: (DialogNode) -> (),
	OnRefresh: () -> (),
	CurrentTree: DialogNode?
): Frame
	ChoiceEditor.SetCurrentTree(CurrentTree)

	local ChoiceId = Choice.Id or ("choice_" .. tostring(Index))
	local IsCollapsed = CollapsedStates[ChoiceId]
	if IsCollapsed == nil then
		IsCollapsed = false
		CollapsedStates[ChoiceId] = false
	end

	local Container = Instance.new("Frame")
	Container.Name = "Choice_" .. tostring(Index)
	Container.Size = UDim2.new(1, 0, 0, IsCollapsed and 56 or 300)
	Container.BackgroundColor3 = Constants.COLORS.Card
	Container.BorderSizePixel = 0
	Container.LayoutOrder = Order
	Container.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Container

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 0)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingRight = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingTop = UDim.new(0, Constants.SIZES.Padding)
	Padding.PaddingBottom = UDim.new(0, Constants.SIZES.Padding)
	Padding.Parent = Container

	local HeaderFrame = Instance.new("Frame")
	HeaderFrame.Size = UDim2.new(1, 0, 0, 32)
	HeaderFrame.BackgroundTransparency = 1
	HeaderFrame.LayoutOrder = 1
	HeaderFrame.Parent = Container

	local HeaderLayout = Instance.new("UIListLayout")
	HeaderLayout.FillDirection = Enum.FillDirection.Horizontal
	HeaderLayout.Padding = UDim.new(0, 8)
	HeaderLayout.VerticalAlignment = Enum.TextXAlignment.Center
	HeaderLayout.Parent = HeaderFrame

	local ChoiceTypeLabel = Instance.new("TextLabel")
	ChoiceTypeLabel.Size = UDim2.new(1, -120, 1, 0)
	ChoiceTypeLabel.Text = "CHOICE"
	ChoiceTypeLabel.TextColor3 = Constants.COLORS.Primary
	ChoiceTypeLabel.BackgroundTransparency = 1
	ChoiceTypeLabel.Font = Constants.FONTS.Bold
	ChoiceTypeLabel.TextSize = 14
	ChoiceTypeLabel.TextXAlignment = Enum.TextXAlignment.Left
	ChoiceTypeLabel.Parent = HeaderFrame

	local ToggleButton = Instance.new("TextButton")
	ToggleButton.Size = UDim2.fromOffset(32, 32)
	ToggleButton.Text = IsCollapsed and "▼" or "▲"
	ToggleButton.TextColor3 = Constants.COLORS.TextSecondary
	ToggleButton.BackgroundColor3 = Constants.COLORS.ButtonBackground
	ToggleButton.BorderSizePixel = 0
	ToggleButton.Font = Constants.FONTS.Bold
	ToggleButton.TextSize = 14
	ToggleButton.AutoButtonColor = false
	ToggleButton.Parent = HeaderFrame

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(0, 4)
	ToggleCorner.Parent = ToggleButton

	local DeleteButton = Instance.new("TextButton")
	DeleteButton.Size = UDim2.fromOffset(70, 32)
	DeleteButton.Text = "Delete"
	DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
	DeleteButton.BorderSizePixel = 0
	DeleteButton.Font = Constants.FONTS.Medium
	DeleteButton.TextSize = 12
	DeleteButton.AutoButtonColor = false
	DeleteButton.Parent = HeaderFrame

	local DeleteCorner = Instance.new("UICorner")
	DeleteCorner.CornerRadius = UDim.new(0, 4)
	DeleteCorner.Parent = DeleteButton

	local ContentFrame = Instance.new("Frame")
	ContentFrame.Name = "Content"
	ContentFrame.Size = UDim2.new(1, 0, 0, 100)
	ContentFrame.BackgroundTransparency = 1
	ContentFrame.Visible = not IsCollapsed
	ContentFrame.LayoutOrder = 2
	ContentFrame.Parent = Container

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.Padding = UDim.new(0, 8)
	ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentLayout.Parent = ContentFrame

	RefreshChoiceContent(Choice, ContentFrame, OnNavigateToNode, OnRefresh)

	ToggleButton.MouseEnter:Connect(function()
		TweenService:Create(ToggleButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.PanelHover}):Play()
	end)

	ToggleButton.MouseLeave:Connect(function()
		TweenService:Create(ToggleButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.ButtonBackground}):Play()
	end)

	DeleteButton.MouseEnter:Connect(function()
		TweenService:Create(DeleteButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.DangerHover}):Play()
	end)

	DeleteButton.MouseLeave:Connect(function()
		TweenService:Create(DeleteButton, TWEEN_INFO, {BackgroundColor3 = Constants.COLORS.Danger}):Play()
	end)

	ToggleButton.MouseButton1Click:Connect(function()
		IsCollapsed = not IsCollapsed
		CollapsedStates[ChoiceId] = IsCollapsed
		ContentFrame.Visible = not IsCollapsed
		ToggleButton.Text = IsCollapsed and "▼" or "▲"

		local NewHeight = IsCollapsed and 56 or (Layout.AbsoluteContentSize.Y + Constants.SIZES.Padding * 2)
		TweenService:Create(Container, TWEEN_INFO, {
			Size = UDim2.new(1, 0, 0, NewHeight)
		}):Play()

		RecalculateAllChoiceHeights(Parent)
	end)

	DeleteButton.MouseButton1Click:Connect(function()
		Prompt.CreateConfirmation(
			Parent:FindFirstAncestorWhichIsA("ScreenGui") or Parent.Parent.Parent,
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
	Components.CreateDropdown(
		Constants.SKILLS,
		Choice.SkillCheck.Skill or "Perception",
		Parent,
		StartOrder + 1,
		function(NewSkill: string)
			Choice.SkillCheck.Skill = NewSkill
		end
	)

	Components.CreateLabel("Difficulty", Parent, StartOrder + 2)
	Components.CreateNumberInput(
		Choice.SkillCheck.Difficulty or 10,
		Parent,
		StartOrder + 3,
		function(NewDiff: number)
			Choice.SkillCheck.Difficulty = NewDiff
		end
	)

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

function ChoiceEditor.ClearCollapsedStates()
	table.clear(CollapsedStates)
end

return ChoiceEditor