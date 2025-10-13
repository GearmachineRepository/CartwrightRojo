--!strict
local UIStateManager = require(script.Parent.Parent.Managers.UIStateManager)
local ZIndexManager = require(script.Parent.Parent.Managers.ZIndexManager)
local Colors = require(script.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Theme.Fonts)

local ViewManager = {}

local TreeViewFrame: Frame? = nil
local EditorViewFrame: Frame? = nil
local GraphViewFrame: Frame? = nil
local MainFrame: Frame? = nil
local DividerFrame: Frame? = nil
local CollapseButton: TextButton? = nil

function ViewManager.Initialize(TreeView: Frame, EditorView: Frame, GraphView: Frame, Main: Frame, Divider: Frame)
	TreeViewFrame = TreeView
	EditorViewFrame = EditorView
	GraphViewFrame = GraphView
	MainFrame = Main
	DividerFrame = Divider

	UIStateManager.Subscribe("ViewChanged", function(NewView: string)
		ViewManager.UpdateViewVisibility(NewView)
	end)

	ViewManager.UpdateViewVisibility(UIStateManager.GetCurrentView())
end

function ViewManager.SwitchToView(ViewName: string)
	UIStateManager.SetCurrentView(ViewName)
end

function ViewManager.UpdateViewVisibility(CurrentView: string)
	if not TreeViewFrame or not EditorViewFrame or not GraphViewFrame or not DividerFrame then
		return
	end

	if CurrentView == "Editor" then
		TreeViewFrame.Visible = true
		EditorViewFrame.Visible = true
		GraphViewFrame.Visible = false
		DividerFrame.Visible = true

		TreeViewFrame.Size = UDim2.new(0, 250, 1, -30)
		EditorViewFrame.Size = UDim2.new(1, -250, 1, -30)
		EditorViewFrame.Position = UDim2.new(0, 250, 0, 30)

	elseif CurrentView == "Graph" then
		TreeViewFrame.Visible = false
		EditorViewFrame.Visible = true
		GraphViewFrame.Visible = true
		DividerFrame.Visible = false

		GraphViewFrame.Size = UDim2.new(0.6, 0, 1, -30)
		GraphViewFrame.Position = UDim2.new(0, 0, 0, 30)

		EditorViewFrame.Size = UDim2.new(0.4, 0, 1, -30)
		EditorViewFrame.Position = UDim2.new(0.6, 0, 0, 30)
	end
end

function ViewManager.GetCurrentView(): string
	return UIStateManager.GetCurrentView()
end

function ViewManager.CreateCollapseButton(EditorPanel: Frame)
	if CollapseButton then
		CollapseButton:Destroy()
	end

	CollapseButton = Instance.new("TextButton")
	CollapseButton.Size = UDim2.new(0, 30, 0, 30)
	CollapseButton.Position = UDim2.new(0, -35, 0, 5)
	CollapseButton.BackgroundColor3 = Colors.Primary
	CollapseButton.BorderSizePixel = 0
	CollapseButton.Text = "◀"
	CollapseButton.TextColor3 = Colors.Text
	CollapseButton.Font = Fonts.Bold
	CollapseButton.TextSize = 16
	CollapseButton.Parent = EditorPanel

	ZIndexManager.SetLayer(CollapseButton, "Overlay")

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = CollapseButton

	local IsCollapsed = false

	CollapseButton.MouseButton1Click:Connect(function()
		IsCollapsed = not IsCollapsed

		if IsCollapsed then
			EditorPanel.Visible = false
			CollapseButton.Text = "▶"
			CollapseButton.Position = UDim2.new(1, -35, 0, 5)

			if TreeViewFrame then
				TreeViewFrame.Size = UDim2.new(1, 0, 1, -30)
			end
		else
			EditorPanel.Visible = true
			CollapseButton.Text = "◀"
			CollapseButton.Position = UDim2.new(0, -35, 0, 5)

			if TreeViewFrame then
				TreeViewFrame.Size = UDim2.new(0, 250, 1, -30)
			end
		end
	end)
end

function ViewManager.UpdateCollapseButtonPosition()
	if CollapseButton and not CollapseButton.Parent then
		return
	end
end

return ViewManager