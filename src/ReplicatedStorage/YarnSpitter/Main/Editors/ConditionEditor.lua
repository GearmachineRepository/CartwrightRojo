--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local ConditionEditor = {}

function ConditionEditor.Render(
	Choice: DialogChoice,
	Container: Frame,
	StartOrder: number,
	OnRefresh: () -> ()
): number
	local CurrentOrder = StartOrder

	if not Choice.Conditions then
		Choice.Conditions = {}
	end

	for Index, Condition in ipairs(Choice.Conditions) do
		local ConditionContainer = Instance.new("Frame")
		ConditionContainer.Size = UDim2.new(1, 0, 0, 100)
		ConditionContainer.BackgroundColor3 = Constants.COLORS.BackgroundLight
		ConditionContainer.BorderSizePixel = 0
		ConditionContainer.LayoutOrder = CurrentOrder
		ConditionContainer.Parent = Container
		CurrentOrder += 1

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 4)
		Corner.Parent = ConditionContainer

		local Layout = Instance.new("UIListLayout")
		Layout.Padding = UDim.new(0, 6)
		Layout.Parent = ConditionContainer

		local Padding = Instance.new("UIPadding")
		Padding.PaddingLeft = UDim.new(0, 8)
		Padding.PaddingRight = UDim.new(0, 8)
		Padding.PaddingTop = UDim.new(0, 8)
		Padding.PaddingBottom = UDim.new(0, 8)
		Padding.Parent = ConditionContainer

		local HeaderRow = Instance.new("Frame")
		HeaderRow.Size = UDim2.new(1, 0, 0, 20)
		HeaderRow.BackgroundTransparency = 1
		HeaderRow.LayoutOrder = 1
		HeaderRow.Parent = ConditionContainer

		local HeaderLabel = Instance.new("TextLabel")
		HeaderLabel.Size = UDim2.new(1, -60, 1, 0)
		HeaderLabel.Text = "Condition " .. tostring(Index)
		HeaderLabel.TextColor3 = Constants.COLORS.TextSecondary
		HeaderLabel.BackgroundTransparency = 1
		HeaderLabel.Font = Constants.FONTS.Bold
		HeaderLabel.TextSize = 12
		HeaderLabel.TextXAlignment = Enum.TextXAlignment.Left
		HeaderLabel.Parent = HeaderRow

		local DeleteButton = Instance.new("TextButton")
		DeleteButton.Size = UDim2.new(0, 50, 1, 0)
		DeleteButton.Position = UDim2.new(1, -50, 0, 0)
		DeleteButton.Text = "✕ Delete"
		DeleteButton.TextColor3 = Constants.COLORS.TextPrimary
		DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
		DeleteButton.Font = Constants.FONTS.Medium
		DeleteButton.TextSize = 11
		DeleteButton.BorderSizePixel = 0
		DeleteButton.AutoButtonColor = false
		DeleteButton.Parent = HeaderRow

		local DeleteCorner = Instance.new("UICorner")
		DeleteCorner.CornerRadius = UDim.new(0, 3)
		DeleteCorner.Parent = DeleteButton

		DeleteButton.MouseEnter:Connect(function()
			DeleteButton.BackgroundColor3 = Constants.COLORS.DangerHover
		end)

		DeleteButton.MouseLeave:Connect(function()
			DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
		end)

		DeleteButton.MouseButton1Click:Connect(function()
			DialogTree.RemoveCondition(Choice, Index)
			task.wait()
			OnRefresh()
		end)

		local TypeRow = Instance.new("Frame")
		TypeRow.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
		TypeRow.BackgroundTransparency = 1
		TypeRow.LayoutOrder = 2
		TypeRow.Parent = ConditionContainer

		Components.CreateInlineLabel("Type:", TypeRow, 50)

		local TypeDropdown = Instance.new("TextButton")
		TypeDropdown.Size = UDim2.new(1, -55, 1, 0)
		TypeDropdown.Position = UDim2.fromOffset(55, 0)
		TypeDropdown.Text = Condition.Type .. " ▼"
		TypeDropdown.TextColor3 = Constants.COLORS.TextPrimary
		TypeDropdown.BackgroundColor3 = Constants.COLORS.InputBackground
		TypeDropdown.Font = Constants.FONTS.Regular
		TypeDropdown.TextSize = 13
		TypeDropdown.BorderSizePixel = 1
		TypeDropdown.BorderColor3 = Constants.COLORS.InputBorder
		TypeDropdown.AutoButtonColor = false
		TypeDropdown.ZIndex = 10
		TypeDropdown.Parent = TypeRow

		local TypeCorner = Instance.new("UICorner")
		TypeCorner.CornerRadius = UDim.new(0, 4)
		TypeCorner.Parent = TypeDropdown

		local TypePadding = Instance.new("UIPadding")
		TypePadding.PaddingLeft = UDim.new(0, 8)
		TypePadding.Parent = TypeDropdown

		local DropdownContainer = Instance.new("Frame")
		DropdownContainer.Size = UDim2.new(1, -55, 0, 0)
		DropdownContainer.Position = UDim2.new(0, 55, 1, 2)
		DropdownContainer.BackgroundTransparency = 1
		DropdownContainer.ZIndex = 100
		DropdownContainer.Parent = TypeRow

		local OptionsFrame = Instance.new("ScrollingFrame")
		OptionsFrame.Size = UDim2.new(1, 0, 0, math.min(#Constants.CONDITION_TYPES * 26, 156))
		OptionsFrame.BackgroundColor3 = Constants.COLORS.Panel
		OptionsFrame.BorderSizePixel = 1
		OptionsFrame.BorderColor3 = Constants.COLORS.Border
		OptionsFrame.Visible = false
		OptionsFrame.ZIndex = 101
		OptionsFrame.ScrollBarThickness = 4
		OptionsFrame.CanvasSize = UDim2.fromOffset(0, #Constants.CONDITION_TYPES * 26)
		OptionsFrame.Parent = DropdownContainer

		local OptionsCorner = Instance.new("UICorner")
		OptionsCorner.CornerRadius = UDim.new(0, 4)
		OptionsCorner.Parent = OptionsFrame

		local OptionsLayout = Instance.new("UIListLayout")
		OptionsLayout.Padding = UDim.new(0, 1)
		OptionsLayout.Parent = OptionsFrame

		local OptionsPadding = Instance.new("UIPadding")
		OptionsPadding.PaddingLeft = UDim.new(0, 2)
		OptionsPadding.PaddingRight = UDim.new(0, 2)
		OptionsPadding.PaddingTop = UDim.new(0, 2)
		OptionsPadding.PaddingBottom = UDim.new(0, 2)
		OptionsPadding.Parent = OptionsFrame

		for _, CondType in ipairs(Constants.CONDITION_TYPES) do
			local OptionButton = Instance.new("TextButton")
			OptionButton.Size = UDim2.new(1, 0, 0, 24)
			OptionButton.Text = CondType
			OptionButton.TextColor3 = Constants.COLORS.TextPrimary
			OptionButton.BackgroundColor3 = CondType == Condition.Type and Constants.COLORS.SelectedBg or Color3.fromRGB(0, 0, 0)
			OptionButton.BackgroundTransparency = CondType == Condition.Type and 0 or 1
			OptionButton.Font = Constants.FONTS.Regular
			OptionButton.TextSize = 13
			OptionButton.BorderSizePixel = 0
			OptionButton.TextXAlignment = Enum.TextXAlignment.Left
			OptionButton.AutoButtonColor = false
			OptionButton.ZIndex = 102
			OptionButton.Parent = OptionsFrame

			local OptionCorner = Instance.new("UICorner")
			OptionCorner.CornerRadius = UDim.new(0, 3)
			OptionCorner.Parent = OptionButton

			local OptionPadding = Instance.new("UIPadding")
			OptionPadding.PaddingLeft = UDim.new(0, 8)
			OptionPadding.Parent = OptionButton

			OptionButton.MouseButton1Click:Connect(function()
				Condition.Type = CondType
				Condition.Value = ""
				TypeDropdown.Text = CondType .. " ▼"
				OptionsFrame.Visible = false
				TypeDropdown.BorderColor3 = Constants.COLORS.InputBorder
				TypeDropdown.BorderSizePixel = 1
			end)
		end

		TypeDropdown.MouseButton1Click:Connect(function()
			OptionsFrame.Visible = not OptionsFrame.Visible
			if OptionsFrame.Visible then
				TypeDropdown.BorderColor3 = Constants.COLORS.Primary
				TypeDropdown.BorderSizePixel = 2
			else
				TypeDropdown.BorderColor3 = Constants.COLORS.InputBorder
				TypeDropdown.BorderSizePixel = 1
			end
		end)

		local ValueLabel = "Value:"
		if Condition.Type == "DialogFlag" then
			ValueLabel = "Flag:"
		elseif Condition.Type == "HasQuest" or Condition.Type == "CompletedQuest" or Condition.Type == "CanTurnInQuest" then
			ValueLabel = "Quest ID:"
		elseif Condition.Type == "HasItem" then
			ValueLabel = "Item:"
		elseif Condition.Type == "Level" then
			ValueLabel = "Min Level:"
		elseif Condition.Type == "HasSkill" then
			ValueLabel = "Skill/Val:"
		elseif Condition.Type == "HasReputation" then
			ValueLabel = "Faction/Val:"
		end

		local ValueRow = Instance.new("Frame")
		ValueRow.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
		ValueRow.BackgroundTransparency = 1
		ValueRow.LayoutOrder = 3
		ValueRow.Parent = ConditionContainer

		Components.CreateInlineLabel(ValueLabel, ValueRow, 80)

		local ValueInput = Instance.new("TextBox")
		ValueInput.Size = UDim2.new(1, -85, 1, 0)
		ValueInput.Position = UDim2.fromOffset(85, 0)
		ValueInput.Text = tostring(Condition.Value)
		ValueInput.TextColor3 = Constants.COLORS.TextPrimary
		ValueInput.BackgroundColor3 = Constants.COLORS.InputBackground
		ValueInput.BorderSizePixel = 1
		ValueInput.BorderColor3 = Constants.COLORS.InputBorder
		ValueInput.Font = Constants.FONTS.Regular
		ValueInput.TextSize = 13
		ValueInput.TextXAlignment = Enum.TextXAlignment.Left
		ValueInput.ClearTextOnFocus = false
		ValueInput.Parent = ValueRow

		local ValueCorner = Instance.new("UICorner")
		ValueCorner.CornerRadius = UDim.new(0, 4)
		ValueCorner.Parent = ValueInput

		local ValuePadding = Instance.new("UIPadding")
		ValuePadding.PaddingLeft = UDim.new(0, 8)
		ValuePadding.PaddingRight = UDim.new(0, 8)
		ValuePadding.Parent = ValueInput

		ValueInput.FocusLost:Connect(function()
			Condition.Value = ValueInput.Text
		end)

		Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ConditionContainer.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + 16)
		end)
	end

	Components.CreateButton(
		"+ Add Condition",
		Container,
		CurrentOrder,
		Constants.COLORS.Primary,
		function()
			DialogTree.AddCondition(Choice, "DialogFlag", "")
			task.wait()
			OnRefresh()
		end
	)
	CurrentOrder += 1

	return CurrentOrder
end

return ConditionEditor