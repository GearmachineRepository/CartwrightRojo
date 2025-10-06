--!strict
local Constants = require(script.Constants)
local DialogTree = require(script.Data.DialogTree)
local CodeGenerator = require(script.Data.CodeGenerator)
local Serializer = require(script.Data.Serializer)
local TreeView = require(script.UI.TreeView)
local EditorPanel = require(script.UI.EditorPanel)
local GraphEditor = require(script.UI.GraphEditor)
local ViewManager = require(script.UI.ViewManager)
local DropdownMenu = require(script.UI.DropdownMenu)
local ResizableDivider = require(script.UI.ResizableDivider)
local Prompt = require(script.UI.Prompt)

type DialogNode = DialogTree.DialogNode

local ToolbarButton = plugin:CreateToolbar("Threader")
local Button = ToolbarButton:CreateButton("Open Editor", "Create and edit dialog trees using Threader", "rbxassetid://124231195330391")

local WidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	500,
	700,
	500,
	700
)

local Version = 2.10

warn("Threader V" ..  tostring(Version))

local Widget = plugin:CreateDockWidgetPluginGui("DialogTreeEditor", WidgetInfo)
Widget.Title = "Threader Editor Window"

local CurrentTree: DialogNode? = nil
local SelectedNode: DialogNode? = nil
local CurrentFileName: string = "UntitledDialog"

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromScale(1, 1)
MainFrame.BackgroundColor3 = Constants.COLORS.Background
MainFrame.Parent = Widget

local TreeScrollFrame: ScrollingFrame
local EditorScroll: ScrollingFrame
local GraphContainer: Frame

local Mouse = plugin:GetMouse()

local function UpdateWindowTitle()
	Widget.Title = "Threading - [" .. CurrentFileName .. "]"
end

local SelectNode

local function RefreshAll()
	local CurrentView = ViewManager.GetCurrentView()

	if CurrentView == "Editor" then
		TreeView.Refresh(TreeScrollFrame, CurrentTree, SelectedNode, SelectNode)
		EditorPanel.Refresh(EditorScroll, SelectedNode, RefreshAll, SelectNode)
	elseif CurrentView == "Graph" then
		GraphEditor.Refresh(CurrentTree, SelectedNode, SelectNode)
		EditorPanel.Refresh(EditorScroll, SelectedNode, RefreshAll, SelectNode)
	end
end

SelectNode = function(Node: DialogNode)
	SelectedNode = Node
	RefreshAll()
end

local function CreateNewTree()
	Prompt.CreateTextInput(
		Widget,
		"Create New Dialog Tree",
		"Enter dialog name...",
		"UntitledDialog",
		function(TreeName: string)
			if TreeName == "" then
				TreeName = "UntitledDialog"
			end

			CurrentTree = DialogTree.CreateNode("start", "Enter greeting text here...")
			SelectedNode = CurrentTree
			CurrentFileName = TreeName
			UpdateWindowTitle()
			RefreshAll()
		end
	)
end

local function SaveTree()
	if not CurrentTree then
		warn("[YarnSpitter] No tree to save!")
		return
	end

	local DialogsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Dialogs")
	if not DialogsFolder then
		DialogsFolder = Instance.new("Folder")
		DialogsFolder.Name = "Dialogs"
		DialogsFolder.Parent = game:GetService("ReplicatedStorage")
	end

	local SavedModule = Serializer.SaveToModule(CurrentTree, CurrentFileName)
	if SavedModule then
		SavedModule.Parent = DialogsFolder
		print("[YarnSpitter] Saved tree as:", CurrentFileName)
		UpdateWindowTitle()
	end
end

local function LoadTree()
	local DialogsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Dialogs")
	if not DialogsFolder then
		warn("[YarnSpitter] No Dialogs folder found!")
		return
	end

	local Modules = {}
	for _, Child in ipairs(DialogsFolder:GetChildren()) do
		if Child:IsA("ModuleScript") and Child:FindFirstChild("TreeData") then
			table.insert(Modules, Child.Name)
		end
	end

	if #Modules == 0 then
		warn("[YarnSpitter] No saved dialog trees found!")
		return
	end

	Prompt.CreateSelection(
		Widget,
		"Load Dialog Tree",
		Modules,
		function(SelectedName: string)
			local ModuleToLoad = DialogsFolder:FindFirstChild(SelectedName)
			if ModuleToLoad then
				local LoadedTree = Serializer.LoadFromModule(ModuleToLoad)
				if LoadedTree then
					CurrentTree = LoadedTree
					SelectedNode = CurrentTree
					CurrentFileName = ModuleToLoad.Name
					UpdateWindowTitle()
					RefreshAll()
					print("[YarnSpitter] Loaded tree:", CurrentFileName)
				end
			end
		end
	)
end

local function RenameTree()
	Prompt.CreateTextInput(
		Widget,
		"Rename Dialog Tree",
		"Enter new name...",
		CurrentFileName,
		function(NewName: string)
			if NewName ~= "" then
				CurrentFileName = NewName
				UpdateWindowTitle()
			end
		end
	)
end

local function GenerateCode()
	if not CurrentTree then
		warn("[YarnSpitter] No tree to generate!")
		return
	end

	local Code = CodeGenerator.Generate(CurrentTree)

	local Success, Result = pcall(function()
		local Module = Instance.new("ModuleScript")
		Module.Name = CurrentFileName
		Module.Source = Code
		Module.Parent = game:GetService("ReplicatedStorage"):WaitForChild("Dialogs")
		return Module
	end)

	if Success then
		print("[YarnSpitter] Generated dialog script successfully!")
		UpdateWindowTitle()
	else
		warn("[YarnSpitter] Failed to create module:", Result)
	end
end

local function SwitchToEditorView()
	ViewManager.SwitchToView("Editor")
	RefreshAll()
end

local function SwitchToGraphView()
	ViewManager.SwitchToView("Graph")
	RefreshAll()
end

local function OnDividerMoved(NewPosition: number)
	TreeView.UpdateSize(NewPosition)
	EditorPanel.UpdateSize(NewPosition)
	ViewManager.UpdateCollapseButtonPosition()
end

local FileMenuItems = {
	{Text = "New", OnClick = CreateNewTree},
	{Text = "Load", OnClick = LoadTree},
	{Text = "Save", OnClick = SaveTree},
	{Text = "Rename", OnClick = RenameTree},
	{Separator = true},
	{Text = "Generate Code", OnClick = GenerateCode}
}

local ViewMenuItems = {
	{Text = "Editor View", OnClick = SwitchToEditorView},
	{Text = "Graph View", OnClick = SwitchToGraphView}
}

local Menus = {
	{Name = "File", Items = FileMenuItems},
	{Name = "View", Items = ViewMenuItems}
}

DropdownMenu.CreateMenuBar(MainFrame, Menus)
TreeScrollFrame = TreeView.Create(MainFrame)
EditorScroll = EditorPanel.Create(MainFrame)
GraphContainer = GraphEditor.Create(MainFrame, Mouse, Widget)
local Divider = ResizableDivider.Create(MainFrame, OnDividerMoved)

local EditorPanelFrame = EditorScroll:FindFirstAncestorOfClass("Frame")
ViewManager.Initialize(TreeScrollFrame, EditorPanelFrame, GraphContainer, MainFrame, Divider)
ViewManager.CreateCollapseButton(EditorPanelFrame)

Button.Click:Connect(function()
	Widget.Enabled = not Widget.Enabled
end)