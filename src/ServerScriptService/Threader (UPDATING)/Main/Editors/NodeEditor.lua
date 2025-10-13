--!strict
local UIStateManager = require(script.Parent.Parent.Managers.UIStateManager)
local ZIndexManager = require(script.Parent.Parent.Managers.ZIndexManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)
local Colors = require(script.Parent.Parent.Theme.Colors)
local Spacing = require(script.Parent.Parent.Theme.Spacing)

local NodeEditor = {}

export type EditorBase = {
	Container: Frame,
	Connections: any,
	Cleanup: () -> ()
}

function NodeEditor.CreateBase(Parent: Instance, Title: string?): EditorBase
	local Container = Instance.new("Frame")
	Container.Size = UDim2.new(1, 0, 0, 100)
	Container.BackgroundTransparency = 1
	Container.Parent = Parent

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Gap)
	Layout.Parent = Container

	local Connections = ConnectionManager.Create()

	ZIndexManager.SetLayer(Container, "UI")

	Connections:Add(Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Container.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y)
	end))

	return {
		Container = Container,
		Connections = Connections,
		Cleanup = function()
			Connections:Cleanup()
			Container:Destroy()
		end
	}
end

function NodeEditor.CreateCollapsibleSection(Parent: Instance, Title: string, StartCollapsed: boolean?): (Frame, Frame)
	local CollapsibleSection = require(script.Parent.Parent.Components.Compound.CollapsibleSection)
	return CollapsibleSection.Create(Title, Parent, StartCollapsed)
end

function NodeEditor.CreateSection(Parent: Instance, Title: string, LayoutOrder: number?): Frame
	local Section = Instance.new("Frame")
	Section.Size = UDim2.fromScale(1, 0)
	Section.BackgroundColor3 = Colors.BackgroundLight
	Section.BorderSizePixel = 0
	Section.LayoutOrder = LayoutOrder or 0
	Section.Parent = Parent

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Section

	local Layout = Instance.new("UIListLayout")
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, Spacing.Gap)
	Layout.Parent = Section

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Spacing.Padding)
	Padding.PaddingRight = UDim.new(0, Spacing.Padding)
	Padding.PaddingTop = UDim.new(0, Spacing.Padding)
	Padding.PaddingBottom = UDim.new(0, Spacing.Padding)
	Padding.Parent = Section

	if Title then
		local Label = require(script.Parent.Parent.Components.Primitives.Label)
		Label.CreateSection(Title, Section, 0)
	end

	Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		Section.Size = UDim2.new(1, 0, 0, Layout.AbsoluteContentSize.Y + Spacing.Padding * 2)
	end)

	return Section
end

return NodeEditor