--!strict
local Colors = require(script.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Theme.Fonts)
local ZIndexManager = require(script.Parent.Parent.Managers.ZIndexManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)

local MenuBar = {}

type MenuItem = {
	Text: string?,
	OnClick: (() -> ())?,
	Separator: boolean?
}

type Menu = {
	Name: string,
	Items: {MenuItem}
}

function MenuBar.CreateMenuBar(Parent: Frame, Menus: {Menu}): Frame
	local Connections = ConnectionManager.Create()

	local MenuBarFrame = Instance.new("Frame")
	MenuBarFrame.Size = UDim2.new(1, 0, 0, 30)
	MenuBarFrame.BackgroundColor3 = Colors.BackgroundDark
	MenuBarFrame.BorderSizePixel = 0
	MenuBarFrame.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Padding = UDim.new(0, 0)
	Layout.Parent = MenuBarFrame

	for _, Menu in ipairs(Menus) do
		local MenuButton = Instance.new("TextButton")
		MenuButton.Size = UDim2.new(0, 80, 1, 0)
		MenuButton.BackgroundColor3 = Colors.BackgroundDark
		MenuButton.BorderSizePixel = 0
		MenuButton.Text = Menu.Name
		MenuButton.TextColor3 = Colors.Text
		MenuButton.Font = Fonts.Medium
		MenuButton.TextSize = 14
		MenuButton.Parent = MenuBarFrame

		local MenuDropdown: Frame? = nil

		Connections:Add(MenuButton.MouseButton1Click:Connect(function()
			if MenuDropdown and MenuDropdown.Visible then
				MenuDropdown.Visible = false
				return
			end

			for _, Child in ipairs(Parent:GetChildren()) do
				if Child:IsA("Frame") and Child.Name:match("^MenuDropdown_") then
					Child.Visible = false
				end
			end

			if not MenuDropdown then
				MenuDropdown = Instance.new("Frame")
				MenuDropdown.Name = "MenuDropdown_" .. Menu.Name
				MenuDropdown.Size = UDim2.fromOffset(200, #Menu.Items * 32)
				MenuDropdown.Position = UDim2.fromOffset(MenuButton.AbsolutePosition.X, MenuButton.AbsolutePosition.Y + MenuButton.AbsoluteSize.Y)
				MenuDropdown.BackgroundColor3 = Colors.BackgroundLight
				MenuDropdown.BorderColor3 = Colors.Border
				MenuDropdown.BorderSizePixel = 1
				MenuDropdown.Visible = false
				MenuDropdown.Parent = Parent

				ZIndexManager.SetLayer(MenuDropdown, "Modal")

				local DropdownCorner = Instance.new("UICorner")
				DropdownCorner.CornerRadius = UDim.new(0, 4)
				DropdownCorner.Parent = MenuDropdown

				local DropdownLayout = Instance.new("UIListLayout")
				DropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
				DropdownLayout.Parent = MenuDropdown

				local ActualHeight = 0

				for Index, Item in ipairs(Menu.Items) do
					if Item.Separator then
						local Separator = Instance.new("Frame")
						Separator.Size = UDim2.new(1, 0, 0, 1)
						Separator.BackgroundColor3 = Colors.Border
						Separator.BorderSizePixel = 0
						Separator.LayoutOrder = Index
						Separator.Parent = MenuDropdown

						ActualHeight = ActualHeight + 1
					else
						local ItemButton = Instance.new("TextButton")
						ItemButton.Size = UDim2.new(1, 0, 0, 32)
						ItemButton.BackgroundTransparency = 1
						ItemButton.Text = "  " .. Item.Text
						ItemButton.TextColor3 = Colors.Text
						ItemButton.Font = Fonts.Regular
						ItemButton.TextSize = 14
						ItemButton.TextXAlignment = Enum.TextXAlignment.Left
						ItemButton.LayoutOrder = Index
						ItemButton.Parent = MenuDropdown

						ActualHeight = ActualHeight + 32

						Connections:Add(ItemButton.MouseButton1Click:Connect(function()
							MenuDropdown.Visible = false
							if Item.OnClick then
								Item.OnClick()
							end
						end))

						Connections:Add(ItemButton.MouseEnter:Connect(function()
							ItemButton.BackgroundColor3 = Colors.BackgroundDark
							ItemButton.BackgroundTransparency = 0
						end))

						Connections:Add(ItemButton.MouseLeave:Connect(function()
							ItemButton.BackgroundTransparency = 1
						end))
					end
				end

				MenuDropdown.Size = UDim2.fromOffset(200, ActualHeight)
			end

			MenuDropdown.Visible = true
		end))

		Connections:Add(MenuButton.MouseEnter:Connect(function()
			MenuButton.BackgroundColor3 = Colors.Background
		end))

		Connections:Add(MenuButton.MouseLeave:Connect(function()
			MenuButton.BackgroundColor3 = Colors.BackgroundDark
		end))
	end

	ZIndexManager.SetLayer(MenuBarFrame, "UI")

	return MenuBarFrame
end

function MenuBar.Cleanup()
end

return MenuBar