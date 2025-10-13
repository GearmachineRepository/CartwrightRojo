--!strict
local Builder = require(script.Parent.Parent.Components.Builder)
local Colors = require(script.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Theme.Spacing)
local ZIndexManager = require(script.Parent.Parent.Managers.ZIndexManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)

local FlagsManagerWindow = {}

local GlobalFlags: {string} = {"None"}
local Connections = ConnectionManager.Create()

function FlagsManagerWindow.GetFlags(): {string}
	return GlobalFlags
end

function FlagsManagerWindow.AddFlag(FlagName: string)
	if not table.find(GlobalFlags, FlagName) and FlagName ~= "" and FlagName ~= "None" then
		table.insert(GlobalFlags, FlagName)
	end
end

function FlagsManagerWindow.RemoveFlag(FlagName: string)
	local Index = table.find(GlobalFlags, FlagName)
	if Index and FlagName ~= "None" then
		table.remove(GlobalFlags, Index)
	end
end

function FlagsManagerWindow.Open(Parent: Frame)
	Connections:Cleanup()
	Connections = ConnectionManager.Create()

	local Overlay = Instance.new("Frame")
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	Overlay.BackgroundTransparency = 0.5
	Overlay.BorderSizePixel = 0
	Overlay.Parent = Parent

	ZIndexManager.SetLayer(Overlay, "Modal")

	local Window = Builder.Panel({
		Title = "Flags Manager",
		Width = 450,
		Height = 500
	})
	Window.Position = UDim2.new(0.5, -225, 0.5, -250)
	Window.Parent = Overlay

	ZIndexManager.SetLayer(Window, "Modal")

	local Description = Builder.Label("Manage global flags used throughout your dialog trees")
	Description.TextColor3 = Colors.TextSecondary
	Description.TextWrapped = true
	Description.Size = UDim2.new(1, 0, 0, 40)
	Description.LayoutOrder = 1
	Description.Parent = Window

	Builder.Spacer(8).Parent = Window

	local AddSection = Instance.new("Frame")
	AddSection.Size = UDim2.new(1, 0, 0, 32)
	AddSection.BackgroundTransparency = 1
	AddSection.LayoutOrder = 3
	AddSection.Parent = Window

	local AddLayout = Instance.new("UIListLayout")
	AddLayout.FillDirection = Enum.FillDirection.Horizontal
	AddLayout.Padding = UDim.new(0, Spacing.Gap)
	AddLayout.Parent = AddSection

	local NewFlagBox = Builder.TextBox({
		PlaceholderText = "Enter new flag name..."
	})
	NewFlagBox.Size = UDim2.new(1, -110, 1, 0)
	NewFlagBox.Parent = AddSection

	local AddButton = Builder.Button({
		Text = "Add Flag",
		Type = "Success",
		OnClick = function()
			local FlagName = NewFlagBox.Text:gsub("^%s*(.-)%s*$", "%1")
			if FlagName ~= "" then
				FlagsManagerWindow.AddFlag(FlagName)
				NewFlagBox.Text = ""
				FlagsManagerWindow.RefreshList(Window)
			end
		end
	})
	AddButton.Size = UDim2.new(0, 100, 1, 0)
	AddButton.Parent = AddSection

	Builder.Spacer(12).Parent = Window
	Builder.Divider().Parent = Window
	Builder.Spacer(12).Parent = Window

	local ListLabel = Builder.Label("Current Flags:", {Bold = true})
	ListLabel.LayoutOrder = 7
	ListLabel.Parent = Window

	Builder.Spacer(4).Parent = Window

	local ListScroll = Instance.new("ScrollingFrame")
	ListScroll.Size = UDim2.new(1, 0, 1, -220)
	ListScroll.BackgroundColor3 = Colors.BackgroundDark
	ListScroll.BorderSizePixel = 0
	ListScroll.ScrollBarThickness = 6
	ListScroll.ScrollBarImageColor3 = Colors.Border
	ListScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	ListScroll.LayoutOrder = 9
	ListScroll.Parent = Window

	local ListCorner = Instance.new("UICorner")
	ListCorner.CornerRadius = UDim.new(0, 4)
	ListCorner.Parent = ListScroll

	local ListLayout = Instance.new("UIListLayout")
	ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ListLayout.Padding = UDim.new(0, Spacing.Small)
	ListLayout.Parent = ListScroll

	local ListPadding = Instance.new("UIPadding")
	ListPadding.PaddingLeft = UDim.new(0, Spacing.Padding)
	ListPadding.PaddingRight = UDim.new(0, Spacing.Padding)
	ListPadding.PaddingTop = UDim.new(0, Spacing.Padding)
	ListPadding.PaddingBottom = UDim.new(0, Spacing.Padding)
	ListPadding.Parent = ListScroll

	Connections:Add(ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + Spacing.Padding * 2)
	end))

	Builder.Spacer(12).Parent = Window

	local CloseButton = Builder.Button({
		Text = "Close",
		OnClick = function()
			Connections:Cleanup()
			Overlay:Destroy()
		end
	})
	CloseButton.Size = UDim2.new(0, 100, 0, 32)
	CloseButton.LayoutOrder = 11
	CloseButton.Parent = Window

	FlagsManagerWindow.RefreshList(Window)

	Connections:Add(NewFlagBox.FocusLost:Connect(function(EnterPressed)
		if EnterPressed then
			local FlagName = NewFlagBox.Text:gsub("^%s*(.-)%s*$", "%1")
			if FlagName ~= "" then
				FlagsManagerWindow.AddFlag(FlagName)
				NewFlagBox.Text = ""
				FlagsManagerWindow.RefreshList(Window)
			end
		end
	end))
end

function FlagsManagerWindow.RefreshList(Window: Frame)
	local ListScroll = Window:FindFirstChild("ScrollingFrame")
	if not ListScroll then return end

	for _, Child in ipairs(ListScroll:GetChildren()) do
		if Child:IsA("Frame") then
			Child:Destroy()
		end
	end

	for Index, Flag in ipairs(GlobalFlags) do
		if Flag == "None" then continue end

		local FlagItem = Instance.new("Frame")
		FlagItem.Size = UDim2.new(1, 0, 0, 32)
		FlagItem.BackgroundColor3 = Colors.BackgroundLight
		FlagItem.BorderSizePixel = 0
		FlagItem.LayoutOrder = Index
		FlagItem.Parent = ListScroll

		local ItemCorner = Instance.new("UICorner")
		ItemCorner.CornerRadius = UDim.new(0, 4)
		ItemCorner.Parent = FlagItem

		local FlagLabel = Instance.new("TextLabel")
		FlagLabel.Size = UDim2.new(1, -80, 1, 0)
		FlagLabel.BackgroundTransparency = 1
		FlagLabel.Text = "  " .. Flag
		FlagLabel.TextColor3 = Colors.Text
		FlagLabel.Font = Fonts.Regular
		FlagLabel.TextSize = 14
		FlagLabel.TextXAlignment = Enum.TextXAlignment.Left
		FlagLabel.Parent = FlagItem

		local DeleteButton = Instance.new("TextButton")
		DeleteButton.Size = UDim2.new(0, 70, 0, 24)
		DeleteButton.Position = UDim2.new(1, -74, 0.5, -12)
		DeleteButton.BackgroundColor3 = Colors.Danger
		DeleteButton.BorderSizePixel = 0
		DeleteButton.Text = "Remove"
		DeleteButton.TextColor3 = Colors.Text
		DeleteButton.Font = Fonts.Medium
		DeleteButton.TextSize = 12
		DeleteButton.Parent = FlagItem

		local DeleteCorner = Instance.new("UICorner")
		DeleteCorner.CornerRadius = UDim.new(0, 4)
		DeleteCorner.Parent = DeleteButton

		Connections:Add(DeleteButton.MouseButton1Click:Connect(function()
			FlagsManagerWindow.RemoveFlag(Flag)
			FlagsManagerWindow.RefreshList(Window)
		end))

		Connections:Add(DeleteButton.MouseEnter:Connect(function()
			DeleteButton.BackgroundColor3 = Color3.fromRGB(240, 100, 100)
		end))

		Connections:Add(DeleteButton.MouseLeave:Connect(function()
			DeleteButton.BackgroundColor3 = Colors.Danger
		end))
	end

	if #GlobalFlags <= 1 then
		local NoFlagsLabel = Instance.new("TextLabel")
		NoFlagsLabel.Size = UDim2.new(1, 0, 0, 40)
		NoFlagsLabel.BackgroundTransparency = 1
		NoFlagsLabel.Text = "No flags created yet"
		NoFlagsLabel.TextColor3 = Colors.TextSecondary
		NoFlagsLabel.Font = Fonts.Regular
		NoFlagsLabel.TextSize = 14
		NoFlagsLabel.Parent = ListScroll
	end
end

return FlagsManagerWindow