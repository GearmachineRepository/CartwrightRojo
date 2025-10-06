--!strict
local Constants = require(script.Parent.Parent.Constants)
local TweenService = game:GetService("TweenService")

export type ViewType = "Editor" | "Graph"

local ViewManager = {}

local CurrentView: ViewType = "Editor"
local EditorPanelCollapsed: boolean = false
local TreeScrollFrame: ScrollingFrame? = nil
local EditorFrame: Frame? = nil
local GraphContainer: Frame? = nil
local CollapseButton: TextButton? = nil
local DividerFrame: Frame? = nil
local MainContainer: Frame? = nil
local CollapseButtonContainer: Frame? = nil

local TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function ViewManager.Initialize(TreeFrame: ScrollingFrame, EditorPanelFrame: Frame, GraphFrame: Frame, MainFrame: Frame, Divider: Frame?)
	TreeScrollFrame = TreeFrame
	EditorFrame = EditorPanelFrame
	GraphContainer = GraphFrame
	MainContainer = MainFrame
	DividerFrame = Divider

	GraphContainer.Visible = false
	TreeScrollFrame.Visible = true
	EditorFrame.Visible = true

	if DividerFrame then
		DividerFrame.Visible = true
	end
end

function ViewManager.SwitchToView(ViewType: ViewType)
	if not TreeScrollFrame or not EditorFrame or not GraphContainer then
		warn("[ViewManager] Not initialized")
		return
	end

	CurrentView = ViewType

	if ViewType == "Editor" then
		GraphContainer.Visible = false
		TreeScrollFrame.Visible = true
		EditorFrame.Visible = true

		local DividerPos = 0.55
		if DividerFrame then
			DividerPos = DividerFrame.Position.X.Scale
			DividerFrame.Visible = true
		end

		EditorFrame.Position = UDim2.new(DividerPos, 5, 0, Constants.SIZES.TopBarHeight + 5)
		EditorFrame.Size = UDim2.new(1 - DividerPos, -10, 1, -Constants.SIZES.TopBarHeight - 10)

		if CollapseButtonContainer then
			CollapseButtonContainer.Visible = false
		end

		EditorPanelCollapsed = false

	elseif ViewType == "Graph" then
		TreeScrollFrame.Visible = false
		GraphContainer.Visible = true
		EditorFrame.Visible = true

		local EditorWidth = 450
        EditorFrame.Position = UDim2.new(1, -EditorWidth + 5, 0, Constants.SIZES.TopBarHeight + 5)
		EditorFrame.Size = UDim2.new(0, EditorWidth - 10, 1, -Constants.SIZES.TopBarHeight - 10)

        if GraphContainer then
            GraphContainer.ZIndex = 1
        end
        if EditorFrame then
            EditorFrame.ZIndex = 100
        end

		if DividerFrame then
			DividerFrame.Visible = false
		end

		if CollapseButtonContainer then
			CollapseButtonContainer.Visible = true
			CollapseButtonContainer.Position = UDim2.new(1, -EditorWidth - 24, 0.5, 0)
		end
	end
end

function ViewManager.GetCurrentView(): ViewType
	return CurrentView
end

function ViewManager.CreateCollapseButton(_: Frame): TextButton
	if not MainContainer then
		warn("[ViewManager] MainContainer not initialized")
		return nil :: any
	end

	CollapseButtonContainer = Instance.new("Frame")
	CollapseButtonContainer.Name = "CollapseButtonContainer"
	CollapseButtonContainer.Size = UDim2.fromOffset(24, 60)
	CollapseButtonContainer.Position = UDim2.new(1, -300, 0.5, 0)
	CollapseButtonContainer.AnchorPoint = Vector2.new(0, 0.5)
	CollapseButtonContainer.BackgroundTransparency = 1
	CollapseButtonContainer.ZIndex = 300
	CollapseButtonContainer.Visible = false
	CollapseButtonContainer.Parent = MainContainer

	local Button = Instance.new("TextButton")
	Button.Size = UDim2.fromScale(1, 1)
	Button.Position = UDim2.fromScale(0, 0)
	Button.Text = "◀"
	Button.TextColor3 = Constants.COLORS.TextPrimary
	Button.BackgroundColor3 = Constants.COLORS.Panel
	Button.BorderSizePixel = 1
	Button.BorderColor3 = Constants.COLORS.Border
	Button.Font = Constants.FONTS.Bold
	Button.TextSize = 16
	Button.AutoButtonColor = false
	Button.ZIndex = 301
	Button.Parent = CollapseButtonContainer

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 6)
	Corner.Parent = Button

	Button.MouseEnter:Connect(function()
		TweenService:Create(Button, TWEEN_INFO, {
			BackgroundColor3 = Constants.COLORS.PanelHover
		}):Play()
	end)

	Button.MouseLeave:Connect(function()
		TweenService:Create(Button, TWEEN_INFO, {
			BackgroundColor3 = Constants.COLORS.Panel
		}):Play()
	end)

	Button.MouseButton1Click:Connect(function()
		ViewManager.ToggleEditorPanel()
	end)

	CollapseButton = Button
	return Button
end

function ViewManager.ToggleEditorPanel()
	if not EditorFrame or not CollapseButton or not CollapseButtonContainer or not MainContainer then
		return
	end

	EditorPanelCollapsed = not EditorPanelCollapsed

	if EditorPanelCollapsed then
		CollapseButton.Text = "▶"

		TweenService:Create(EditorFrame, TWEEN_INFO, {
			Position = UDim2.new(1, 10, 0, Constants.SIZES.TopBarHeight + 5)
		}):Play()

		TweenService:Create(CollapseButtonContainer, TWEEN_INFO, {
			Position = UDim2.new(1, -28, 0.5, 0)
		}):Play()
	else
		CollapseButton.Text = "◀"

		TweenService:Create(EditorFrame, TWEEN_INFO, {
			Position = UDim2.new(1, -EditorFrame.AbsoluteSize.X, 0, Constants.SIZES.TopBarHeight + 5)
		}):Play()

		TweenService:Create(CollapseButtonContainer, TWEEN_INFO, {
			Position = UDim2.new(1, -EditorFrame.AbsoluteSize.X - 28, 0.5, 0)
		}):Play()
	end
end

function ViewManager.IsEditorPanelCollapsed(): boolean
	return EditorPanelCollapsed
end

function ViewManager.UpdateCollapseButtonPosition()
	if not CollapseButtonContainer or not EditorFrame or EditorPanelCollapsed or CurrentView ~= "Graph" then
		return
	end

	CollapseButtonContainer.Position = UDim2.new(1, -EditorFrame.AbsoluteSize.X - 28, 0.5, 0)
end

return ViewManager