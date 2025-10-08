--!strict
local Constants = require(script.Parent.Parent.Constants)
local FlagsManager = require(script.Parent.Parent.Data.FlagsManager)
local Prompt = require(script.Parent.Prompt)

local FlagsManagerUI = {}

function FlagsManagerUI.Open(Parent: Instance)
	local Overlay = Instance.new("Frame")
	Overlay.Name = "FlagsManagerOverlay"
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	Overlay.BackgroundTransparency = 0.5
	Overlay.ZIndex = 1000
	Overlay.Parent = Parent

	local Window = Instance.new("Frame")
	Window.Name = "FlagsManagerWindow"
	Window.Size = UDim2.fromOffset(500, 600)
	Window.Position = UDim2.fromScale(0.5, 0.5)
	Window.AnchorPoint = Vector2.new(0.5, 0.5)
	Window.BackgroundColor3 = Constants.COLORS.Panel
	Window.BorderSizePixel = 1
	Window.BorderColor3 = Constants.COLORS.Border
	Window.ZIndex = 1001
	Window.Parent = Overlay

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 8)
	Corner.Parent = Window

	local Title = Instance.new("TextLabel")
	Title.Name = "Title"
	Title.Size = UDim2.new(1, -20, 0, 40)
	Title.Position = UDim2.fromOffset(10, 10)
	Title.Text = "Flag Manager"
	Title.TextColor3 = Constants.COLORS.TextPrimary
	Title.BackgroundTransparency = 1
	Title.Font = Constants.FONTS.Bold
	Title.TextSize = 18
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.ZIndex = 1002
	Title.Parent = Window

	local CloseButton = Instance.new("TextButton")
	CloseButton.Size = UDim2.fromOffset(30, 30)
	CloseButton.Position = UDim2.new(1, -40, 0, 10)
	CloseButton.Text = "✕"
	CloseButton.TextColor3 = Constants.COLORS.TextPrimary
	CloseButton.BackgroundColor3 = Constants.COLORS.Danger
	CloseButton.BorderSizePixel = 0
	CloseButton.Font = Constants.FONTS.Bold
	CloseButton.TextSize = 16
	CloseButton.ZIndex = 1002
	CloseButton.Parent = Window

	local CloseCorner = Instance.new("UICorner")
	CloseCorner.CornerRadius = UDim.new(0, 4)
	CloseCorner.Parent = CloseButton

	CloseButton.MouseButton1Click:Connect(function()
		Overlay:Destroy()
	end)

    local AddButton = Instance.new("TextButton")
    AddButton.Size = UDim2.new(1, -20, 0, 35)
    AddButton.Position = UDim2.fromOffset(10, 60)
    AddButton.Text = "+ Add New Flag"
    AddButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    AddButton.BackgroundColor3 = Constants.COLORS.Primary
    AddButton.BorderSizePixel = 0
    AddButton.Font = Constants.FONTS.Medium
    AddButton.TextSize = 14
    AddButton.ZIndex = 1002
    AddButton.Parent = Window

    local AddCorner = Instance.new("UICorner")
    AddCorner.CornerRadius = UDim.new(0, 4)
    AddCorner.Parent = AddButton

    AddButton.MouseButton1Click:Connect(function()
        Prompt.CreateTextInput(
            Parent:FindFirstAncestorWhichIsA("ScreenGui") or Parent,
            "New Flag",
            "Enter the flag name:",
            "",
            function(FlagName: string)
                if FlagName and FlagName ~= "" then
                    FlagsManager.AddFlag(FlagName)
                    FlagsManagerUI.RefreshList(Window)
                end
            end
        )
    end)

	local ScrollFrame = Instance.new("ScrollingFrame")
	ScrollFrame.Name = "FlagsList"
	ScrollFrame.Size = UDim2.new(1, -20, 1, -115)
	ScrollFrame.Position = UDim2.fromOffset(10, 105)
	ScrollFrame.BackgroundColor3 = Constants.COLORS.BackgroundDark
	ScrollFrame.BorderSizePixel = 1
	ScrollFrame.BorderColor3 = Constants.COLORS.Border
	ScrollFrame.ScrollBarThickness = 6
	ScrollFrame.ScrollBarImageColor3 = Constants.COLORS.Border
	ScrollFrame.ZIndex = 1002
	ScrollFrame.Parent = Window

	local ScrollCorner = Instance.new("UICorner")
	ScrollCorner.CornerRadius = UDim.new(0, 4)
	ScrollCorner.Parent = ScrollFrame

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 5)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = ScrollFrame

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 10)
	Padding.PaddingRight = UDim.new(0, 10)
	Padding.PaddingTop = UDim.new(0, 10)
	Padding.Parent = ScrollFrame

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ScrollFrame.CanvasSize = UDim2.fromOffset(0, Layout.AbsoluteContentSize.Y + 20)
	end)

	FlagsManagerUI.RefreshList(Window)
end

function FlagsManagerUI.RefreshList(Window: Frame)
	local ScrollFrame = Window:FindFirstChild("FlagsList") :: ScrollingFrame
	if not ScrollFrame then return end

	for _, Child in ipairs(ScrollFrame:GetChildren()) do
		if not Child:IsA("UIListLayout") and not Child:IsA("UIPadding") then
			Child:Destroy()
		end
	end

	local Flags = FlagsManager.GetAllFlags()

	for Index, FlagName in ipairs(Flags) do
		local FlagRow = Instance.new("Frame")
		FlagRow.Name = "Flag_" .. FlagName
		FlagRow.Size = UDim2.new(1, 0, 0, 35)
		FlagRow.BackgroundColor3 = Constants.COLORS.Panel
		FlagRow.BorderSizePixel = 1
		FlagRow.BorderColor3 = Constants.COLORS.Border
		FlagRow.LayoutOrder = Index
		FlagRow.ZIndex = 1003
		FlagRow.Parent = ScrollFrame

		local RowCorner = Instance.new("UICorner")
		RowCorner.CornerRadius = UDim.new(0, 4)
		RowCorner.Parent = FlagRow

		local FlagLabel = Instance.new("TextLabel")
		FlagLabel.Size = UDim2.new(1, -70, 1, 0)
		FlagLabel.Position = UDim2.fromOffset(10, 0)
		FlagLabel.Text = FlagName
		FlagLabel.TextColor3 = Constants.COLORS.TextPrimary
		FlagLabel.BackgroundTransparency = 1
		FlagLabel.Font = Constants.FONTS.Regular
		FlagLabel.TextSize = 14
		FlagLabel.TextXAlignment = Enum.TextXAlignment.Left
		FlagLabel.ZIndex = 1004
		FlagLabel.Parent = FlagRow

		local DeleteButton = Instance.new("TextButton")
		DeleteButton.Size = UDim2.fromOffset(50, 25)
		DeleteButton.Position = UDim2.new(1, -60, 0.5, -12.5)
		DeleteButton.Text = "Delete"
		DeleteButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		DeleteButton.BackgroundColor3 = Constants.COLORS.Danger
		DeleteButton.BorderSizePixel = 0
		DeleteButton.Font = Constants.FONTS.Medium
		DeleteButton.TextSize = 11
		DeleteButton.ZIndex = 1004
		DeleteButton.Parent = FlagRow

		local DeleteCorner = Instance.new("UICorner")
		DeleteCorner.CornerRadius = UDim.new(0, 4)
		DeleteCorner.Parent = DeleteButton

		DeleteButton.MouseButton1Click:Connect(function()
			FlagsManager.RemoveFlag(FlagName)
			FlagsManagerUI.RefreshList(Window)
		end)
	end
end

return FlagsManagerUI