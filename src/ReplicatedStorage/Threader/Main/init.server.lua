--!strict
local RunService = game:GetService("RunService")

if not RunService.IsStudio or not RunService:IsEdit() then
	return
end

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
local FlagsManagerUI = require(script.UI.FlagsManagerUI)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

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

local Version = 2.11

warn("Threader V" ..  tostring(Version))

local Widget = plugin:CreateDockWidgetPluginGui("DialogTreeEditor", WidgetInfo)
Widget.Title = "Threader Editor Window"

local CurrentTree: DialogNode? = nil
local SelectedNode: DialogNode? = nil
local SelectedChoice: DialogChoice? = nil
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
local SelectChoice

local function RefreshAll()
	local CurrentView = ViewManager.GetCurrentView()

	if CurrentView == "Editor" then
		TreeView.Refresh(TreeScrollFrame, CurrentTree, SelectedNode, SelectedChoice, SelectNode, SelectChoice)
		EditorPanel.Refresh(EditorScroll, SelectedNode, SelectedChoice, RefreshAll, SelectNode, SelectChoice, CurrentTree)
	elseif CurrentView == "Graph" then
		GraphEditor.Refresh(CurrentTree, SelectedNode, SelectedChoice, SelectNode, SelectChoice)
		EditorPanel.Refresh(EditorScroll, SelectedNode, SelectedChoice, RefreshAll, SelectNode, SelectChoice, CurrentTree)
	end
end

SelectNode = function(Node: DialogNode)
	SelectedNode = Node
	SelectedChoice = nil
	RefreshAll()
end

SelectChoice = function(Choice: DialogChoice)
	SelectedChoice = Choice
	SelectedNode = nil
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
			SelectedChoice = nil
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

	local Success, JsonString = pcall(function()
		return Serializer.Serialize(CurrentTree)
	end)

	if not Success then
		warn("[YarnSpitter] Failed to serialize:", JsonString)
		return
	end

	local DataStoreFolder = game:GetService("ServerStorage"):FindFirstChild("DialogTrees")
	if not DataStoreFolder then
		DataStoreFolder = Instance.new("Folder")
		DataStoreFolder.Name = "DialogTrees"
		DataStoreFolder.Parent = game:GetService("ServerStorage")
	end

	local ExistingData = DataStoreFolder:FindFirstChild(CurrentFileName)
	if ExistingData then
		ExistingData:Destroy()
	end

	local DataValue = Instance.new("StringValue")
	DataValue.Name = CurrentFileName
	DataValue.Value = JsonString
	DataValue.Parent = DataStoreFolder

	print("[YarnSpitter] Saved dialog tree:", CurrentFileName)
	UpdateWindowTitle()
end

local function LoadTree()
	local DataStoreFolder = game:GetService("ServerStorage"):FindFirstChild("DialogTrees")
	if not DataStoreFolder then
		warn("[YarnSpitter] No saved trees found!")
		return
	end

	local TreeNames = {}
	for _, Child in ipairs(DataStoreFolder:GetChildren()) do
		if Child:IsA("StringValue") then
			table.insert(TreeNames, Child.Name)
		end
	end

	if #TreeNames == 0 then
		warn("[YarnSpitter] No saved trees found!")
		return
	end

	Prompt.CreateDropdownPrompt(
		Widget,
		"Load Dialog Tree",
		TreeNames,
		function(SelectedTreeName: string)
			local DataValue = DataStoreFolder:FindFirstChild(SelectedTreeName)
			if not DataValue or not DataValue:IsA("StringValue") then
				warn("[YarnSpitter] Tree not found:", SelectedTreeName)
				return
			end

			local Success, LoadedTree = pcall(function()
				return Serializer.Deserialize(DataValue.Value)
			end)

			if Success and LoadedTree then
				CurrentTree = LoadedTree
				SelectedNode = CurrentTree
				SelectedChoice = nil
				CurrentFileName = SelectedTreeName
				UpdateWindowTitle()
				RefreshAll()
				print("[YarnSpitter] Loaded dialog tree:", SelectedTreeName)
			else
				warn("[YarnSpitter] Failed to deserialize:", LoadedTree)
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
			if NewName == "" then
				return
			end

			CurrentFileName = NewName
			UpdateWindowTitle()
		end
	)
end

local function GenerateCode()
	if not CurrentTree then
		warn("[YarnSpitter] No tree to generate code from!")
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

local FlagsMenuItems = {
	{Text = "Manage Flags", OnClick = function()
		FlagsManagerUI.Open(MainFrame)
	end}
}

local Menus = {
	{Name = "File", Items = FileMenuItems},
	{Name = "View", Items = ViewMenuItems},
	{Name = "Flags", Items = FlagsMenuItems}  -- NEW
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