--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")

local DropdownMenu = {}

local TWEEN_INFO = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ActiveMenu: Frame? = nil

type MenuItem = {
	Text: string,
	OnClick: () -> (),
	Separator: boolean?
}

local function CloseActiveMenu()
	if ActiveMenu then
		ActiveMenu:Destroy()
		ActiveMenu = nil
	end
end

local function CreateMenuButton(Text: string, Parent: Instance, LayoutOrder: number): TextButton
	local Button = Instance.new("TextButton")
	Button.Size = UDim2.fromOffset(60, 34)
	Button.Text = Text
	Button.TextColor3 = Constants.COLORS.TextPrimary
	Button.BackgroundTransparency = 1
	Button.Font = Constants.FONTS.Medium
	Button.TextSize = Constants.TEXT_SIZES.Normal
	Button.AutoButtonColor = false
	Button.LayoutOrder = LayoutOrder
	Button.ZIndex = 1001
	Button.Parent = Parent

	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TWEEN_INFO, {
			BackgroundTransparency = 0,
			BackgroundColor3 = Constants.COLORS.PanelHover
		}):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TWEEN_INFO, {
			BackgroundTransparency = 1
		}):Play()
	end)

	return Button
end

local function CreateDropdownPanel(AnchorButton: TextButton, Items: {MenuItem}): Frame
	CloseActiveMenu()

	local ScreenGui = AnchorButton:FindFirstAncestorOfClass("ScreenGui") or AnchorButton:FindFirstAncestorWhichIsA("LayerCollector")

	local Panel = Instance.new("Frame")
	Panel.Size = UDim2.fromOffset(200, 0)
	Panel.Position = UDim2.fromOffset(AnchorButton.AbsolutePosition.X, AnchorButton.AbsolutePosition.Y + AnchorButton.AbsoluteSize.Y + 2)
	Panel.BackgroundColor3 = Constants.COLORS.Panel
	Panel.BorderSizePixel = 1
	Panel.BorderColor3 = Constants.COLORS.Border
	Panel.ZIndex = 999999
	Panel.Parent = ScreenGui

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, Constants.SIZES.CornerRadius)
	Corner.Parent = Panel

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Constants.COLORS.BorderLight
	Stroke.Thickness = 1
	Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	Stroke.Parent = Panel

	local Layout = Instance.new("UIListLayout")
	Layout.Padding = UDim.new(0, 2)
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Parent = Panel

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, 4)
	Padding.PaddingRight = UDim.new(0, 4)
	Padding.PaddingTop = UDim.new(0, 4)
	Padding.PaddingBottom = UDim.new(0, 4)
	Padding.Parent = Panel

	for Index, Item in ipairs(Items) do
		if Item.Separator then
			local Separator = Instance.new("Frame")
			Separator.Size = UDim2.new(1, 0, 0, 1)
			Separator.BackgroundColor3 = Constants.COLORS.Border
			Separator.BorderSizePixel = 0
			Separator.LayoutOrder = Index
			Separator.ZIndex = 999999
			Separator.Parent = Panel
		else
			local ItemButton = Instance.new("TextButton")
			ItemButton.Size = UDim2.new(1, 0, 0, 32)
			ItemButton.Text = Item.Text
			ItemButton.TextColor3 = Constants.COLORS.TextPrimary
			ItemButton.BackgroundTransparency = 1
			ItemButton.Font = Constants.FONTS.Regular
			ItemButton.TextSize = Constants.TEXT_SIZES.Normal
			ItemButton.TextXAlignment = Enum.TextXAlignment.Left
			ItemButton.AutoButtonColor = false
			ItemButton.LayoutOrder = Index
			ItemButton.ZIndex = 1000000
			ItemButton.Parent = Panel

			local ItemPadding = Instance.new("UIPadding")
			ItemPadding.PaddingLeft = UDim.new(0, 12)
			ItemPadding.PaddingRight = UDim.new(0, 12)
			ItemPadding.Parent = ItemButton

			local ItemCorner = Instance.new("UICorner")
			ItemCorner.CornerRadius = UDim.new(0, 4)
			ItemCorner.Parent = ItemButton

			ItemButton.MouseEnter:Connect(function()
				TweenService:Create(ItemButton, TWEEN_INFO, {
					BackgroundTransparency = 0,
					BackgroundColor3 = Constants.COLORS.PanelHover
				}):Play()
			end)

			ItemButton.MouseLeave:Connect(function()
				TweenService:Create(ItemButton, TWEEN_INFO, {
					BackgroundTransparency = 1
				}):Play()
			end)

			ItemButton.MouseButton1Click:Connect(function()
				CloseActiveMenu()
				Item.OnClick()
			end)
		end
	end

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Panel.Size = UDim2.fromOffset(200, Layout.AbsoluteContentSize.Y + 8)
	end)

	ActiveMenu = Panel
	return Panel
end

function DropdownMenu.CreateMenuBar(Parent: Instance, Menus: {{Name: string, Items: {MenuItem}}}): Frame
	local MenuBar = Instance.new("Frame")
	MenuBar.Size = UDim2.new(1, 0, 0, Constants.SIZES.TopBarHeight)
	MenuBar.BackgroundColor3 = Constants.COLORS.BackgroundDark
	MenuBar.BorderSizePixel = 0
	MenuBar.ZIndex = 1000
	MenuBar.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Padding = UDim.new(0, 4)
	Layout.VerticalAlignment = Enum.VerticalAlignment.Center
	Layout.Parent = MenuBar

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.PaddingTop = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.PaddingBottom = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.Parent = MenuBar

	local ActiveMenuButton: TextButton? = nil

	for Index, Menu in ipairs(Menus) do
		local MenuButton = CreateMenuButton(Menu.Name, MenuBar, Index)

		MenuButton.MouseButton1Click:Connect(function()
			if ActiveMenu and ActiveMenuButton == MenuButton then
				CloseActiveMenu()
				ActiveMenuButton = nil
			else
				CreateDropdownPanel(MenuButton, Menu.Items)
				ActiveMenuButton = MenuButton
			end
		end)
	end

	return MenuBar
end

function DropdownMenu.CloseAll()
	CloseActiveMenu()
end

return DropdownMenu