--!strict
local Colors = require(script.Parent.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Parent.Theme.Spacing)
local UIStateManager = require(script.Parent.Parent.Parent.Managers.UIStateManager)

local CollapsibleSection = {}

function CollapsibleSection.Create(Title: string, Parent: Instance, StartCollapsed: boolean?, LayoutOrder: number?): (Frame, Frame)
	local SectionId = "section_" .. Title
	local IsCollapsed = UIStateManager.IsCollapsed(SectionId)

	if StartCollapsed ~= nil then
		IsCollapsed = StartCollapsed
		UIStateManager.SetCollapsed(SectionId, IsCollapsed)
	end

	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 100)
	Container.BackgroundTransparency = 1
	Container.LayoutOrder = LayoutOrder or 0
	Container.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Small)
	Layout.Parent = Container

	local Header = Instance.new("TextButton")
	Header.Size = UDim2.new(1, 0, 0, 28)
	Header.BackgroundColor3 = Colors.BackgroundLight
	Header.BorderSizePixel = 0
	Header.Text = "  " .. (IsCollapsed and "▶" or "▼") .. "  " .. Title
	Header.TextColor3 = Colors.Text
	Header.Font = Fonts.Bold
	Header.TextSize = 14
	Header.TextXAlignment = Enum.TextXAlignment.Left
	Header.LayoutOrder = 1
	Header.Parent = Container

	local HeaderCorner = Instance.new("UICorner")
	HeaderCorner.CornerRadius = UDim.new(0, 4)
	HeaderCorner.Parent = Header

	local Content = Instance.new("Frame")
	Content.Size = UDim2.fromScale(1, 0)
	Content.BackgroundTransparency = 1
	Content.Visible = not IsCollapsed
	Content.LayoutOrder = 2
	Content.Parent = Container

	local ContentLayout = Instance.new("UIListLayout")
	ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ContentLayout.Padding = UDim.new(0, Spacing.Gap)
	ContentLayout.Parent = Content

	Header.MouseButton1Click:Connect(function()
		IsCollapsed = not IsCollapsed
		Content.Visible = not IsCollapsed
		Header.Text = "  " .. (IsCollapsed and "▶" or "▼") .. "  " .. Title
		UIStateManager.SetCollapsed(SectionId, IsCollapsed)
	end)

	ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Content.Size = UDim2.new(1, 0, 0, ContentLayout.AbsoluteContentSize.Y)
		Container.Size = UDim2.new(1, 0, 0, 28 + Spacing.Small + ContentLayout.AbsoluteContentSize.Y)
	end)

	return Container, Content
end

return CollapsibleSection