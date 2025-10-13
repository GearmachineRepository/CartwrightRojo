--!strict
local Colors = require(script.Parent.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Parent.Theme.Fonts)

local Button = {}

function Button.Create(Text: string, Parent: Instance, OnClick: () -> (), LayoutOrder: number?): TextButton
	local ButtonElement = Instance.new("TextButton")
	ButtonElement.Size = UDim2.fromOffset(100, 28)
	ButtonElement.BackgroundColor3 = Colors.Primary
	ButtonElement.BorderSizePixel = 0
	ButtonElement.Text = Text
	ButtonElement.TextColor3 = Colors.Text
	ButtonElement.Font = Fonts.Medium
	ButtonElement.TextSize = 14
	ButtonElement.LayoutOrder = LayoutOrder or 0
	ButtonElement.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 4)
	Corner.Parent = ButtonElement

	ButtonElement.MouseButton1Click:Connect(OnClick)

	ButtonElement.MouseEnter:Connect(function()
		ButtonElement.BackgroundColor3 = Colors.PrimaryHover
	end)

	ButtonElement.MouseLeave:Connect(function()
		ButtonElement.BackgroundColor3 = Colors.Primary
	end)

	return ButtonElement
end

function Button.CreateDanger(Text: string, Parent: Instance, OnClick: () -> (), LayoutOrder: number?): TextButton
	local ButtonElement = Button.Create(Text, Parent, OnClick, LayoutOrder)
	ButtonElement.BackgroundColor3 = Colors.Danger

	ButtonElement.MouseEnter:Connect(function()
		ButtonElement.BackgroundColor3 = Color3.fromRGB(240, 100, 100)
	end)

	ButtonElement.MouseLeave:Connect(function()
		ButtonElement.BackgroundColor3 = Colors.Danger
	end)

	return ButtonElement
end

function Button.CreateSuccess(Text: string, Parent: Instance, OnClick: () -> (), LayoutOrder: number?): TextButton
	local ButtonElement = Button.Create(Text, Parent, OnClick, LayoutOrder)
	ButtonElement.BackgroundColor3 = Colors.Success

	ButtonElement.MouseEnter:Connect(function()
		ButtonElement.BackgroundColor3 = Color3.fromRGB(100, 220, 140)
	end)

	ButtonElement.MouseLeave:Connect(function()
		ButtonElement.BackgroundColor3 = Colors.Success
	end)

	return ButtonElement
end

return Button