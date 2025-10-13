--!strict
local Colors = require(script.Parent.Parent.Theme.Colors)
local Icons = require(script.Parent.Parent.Theme.Icons)
local Spacing = require(script.Parent.Parent.Theme.Spacing)

local Toolbar = {}

export type ToolbarButton = {
	Icon: string,
	Tooltip: string,
	OnClick: () -> (),
	Enabled: () -> boolean
}

function Toolbar.Create(Parent: Frame, Buttons: {ToolbarButton}): Frame
	local Container = Instance.new("Frame")
	Container.Name = "Toolbar"
	Container.Size = UDim2.new(1, 0, 0, 40)
	Container.BackgroundColor3 = Colors.BackgroundLight
	Container.BorderSizePixel = 0
	Container.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Horizontal
	Layout.Padding = UDim.new(0, 4)
	Layout.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.Padding)
	Padding.PaddingRight = UDim.new(0, Spacing.Padding)
	Padding.PaddingTop = UDim.new(0, 4)
	Padding.PaddingBottom = UDim.new(0, 4)
	Padding.Parent = Container

	for _, ButtonData in ipairs(Buttons) do
		local Button = Instance.new("ImageButton")
		Button.Size = UDim2.fromOffset(32, 32)
		Button.BackgroundColor3 = Colors.Background
		Button.BorderSizePixel = 0
		Button.Image = ButtonData.Icon
		Button.Parent = Container

		local Corner = Instance.new("UICorner")
		Corner.CornerRadius = UDim.new(0, 4)
		Corner.Parent = Button

		Button.MouseButton1Click:Connect(function()
			if ButtonData.Enabled() then
				ButtonData.OnClick()
			end
		end)

		Button.MouseEnter:Connect(function()
			if ButtonData.Enabled() then
				Button.BackgroundColor3 = Colors.BackgroundLight
			end
		end)

		Button.MouseLeave:Connect(function()
			Button.BackgroundColor3 = Colors.Background
		end)
	end

	return Container
end

return Toolbar