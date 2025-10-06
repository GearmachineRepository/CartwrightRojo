--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local FlagsEditor = {}

function FlagsEditor.Render(
	Choice: DialogChoice,
	Container: Frame,
	StartOrder: number,
	OnRefresh: () -> ()
): number
	local CurrentOrder = StartOrder

	if not Choice.SetFlags then
		Choice.SetFlags = {}
	end

	for Index, FlagName in ipairs(Choice.SetFlags) do
		local FlagRow = Instance.new("Frame")
		FlagRow.Size = UDim2.new(1, 0, 0, Constants.SIZES.InputHeight)
		FlagRow.BackgroundTransparency = 1
		FlagRow.LayoutOrder = CurrentOrder
		FlagRow.Parent = Container
		CurrentOrder += 1

		Components.CreateInlineLabel("Flag " .. tostring(Index) .. ":", FlagRow, 60)

		local FlagInput = Instance.new("TextBox")
		FlagInput.Size = UDim2.new(1, -130, 1, 0)
		FlagInput.Position = UDim2.fromOffset(65, 0)
		FlagInput.Text = FlagName
		FlagInput.TextColor3 = Constants.COLORS.TextPrimary
		FlagInput.BackgroundColor3 = Constants.COLORS.InputBackground
		FlagInput.BorderSizePixel = 1
		FlagInput.BorderColor3 = Constants.COLORS.InputBorder
		FlagInput.Font = Constants.FONTS.Regular
		FlagInput.TextSize = 13
		FlagInput.TextXAlignment = Enum.TextXAlignment.Left
		FlagInput.ClearTextOnFocus = false
		FlagInput.Parent = FlagRow

		local InputCorner = Instance.new("UICorner")
		InputCorner.CornerRadius = UDim.new(0, 4)
		InputCorner.Parent = FlagInput

		local InputPadding = Instance.new("UIPadding")
		InputPadding.PaddingLeft = UDim.new(0, 8)
		InputPadding.PaddingRight = UDim.new(0, 8)
		InputPadding.Parent = FlagInput

		FlagInput.FocusLost:Connect(function()
			Choice.SetFlags[Index] = FlagInput.Text
		end)

		local DeleteButton = Instance.new("TextButton")
		DeleteButton.Size = UDim2.new(0, 60, 1, 0)
		DeleteButton.Position = UDim2.new(1, -60, 0, 0)
		DeleteButton.Text = "✕"
		DeleteButton.TextColor3 = Constants.COLORS.TextPrimary
		DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
		DeleteButton.Font = Constants.FONTS.Bold
		DeleteButton.TextSize = 16
		DeleteButton.BorderSizePixel = 0
		DeleteButton.AutoButtonColor = false
		DeleteButton.Parent = FlagRow

		local DeleteCorner = Instance.new("UICorner")
		DeleteCorner.CornerRadius = UDim.new(0, 4)
		DeleteCorner.Parent = DeleteButton

		DeleteButton.MouseEnter:Connect(function()
			DeleteButton.BackgroundColor3 = Constants.COLORS.DangerHover
		end)

		DeleteButton.MouseLeave:Connect(function()
			DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
		end)

		DeleteButton.MouseButton1Click:Connect(function()
			DialogTree.RemoveFlag(Choice, Index)
			task.wait()
			OnRefresh()
		end)
	end

	Components.CreateButton(
		"+ Add Flag",
		Container,
		CurrentOrder,
		Constants.COLORS.Primary,
		function()
			DialogTree.AddFlag(Choice, "NewFlag")
			task.wait()
			OnRefresh()
		end
	)
	CurrentOrder += 1

	return CurrentOrder
end

return FlagsEditor