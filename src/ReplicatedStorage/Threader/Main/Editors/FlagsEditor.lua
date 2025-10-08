--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)
local FlagsManager = require(script.Parent.Parent.Data.FlagsManager)

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

		local DropdownContainer = Instance.new("Frame")
		DropdownContainer.Size = UDim2.new(1, -130, 1, 0)
		DropdownContainer.Position = UDim2.fromOffset(65, 0)
		DropdownContainer.BackgroundTransparency = 1
		DropdownContainer.Parent = FlagRow

		local AllFlags = FlagsManager.GetAllFlags()

		Components.CreateDropdown(
			AllFlags,
			FlagName,
			DropdownContainer,
			1,
			function(NewFlag: string)
				if NewFlag == "None" then
					DialogTree.RemoveFlag(Choice, Index)
					task.wait()
					OnRefresh()
				else
					Choice.SetFlags[Index] = NewFlag
				end
			end
		)

		local DeleteButton = Instance.new("TextButton")
		DeleteButton.Size = UDim2.new(0, 60, 1, 0)
		DeleteButton.Position = UDim2.new(1, -60, 0, 0)
		DeleteButton.Text = "✕"
		DeleteButton.TextColor3 = Constants.COLORS.TextPrimary
		DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
		DeleteButton.BorderSizePixel = 0
		DeleteButton.Font = Constants.FONTS.Bold
		DeleteButton.TextSize = 16
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
			DialogTree.AddFlag(Choice, "None")
			task.wait()
			OnRefresh()
		end
	)
	CurrentOrder += 1

	return CurrentOrder
end

return FlagsEditor