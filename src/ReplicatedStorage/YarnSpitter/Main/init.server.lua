--!strict
local Constants = require(script.Constants)
local DialogTree = require(script.Data.DialogTree)
local CodeGenerator = require(script.Data.CodeGenerator)
local Serializer = require(script.Data.Serializer)
local TreeView = require(script.UI.TreeView)
local EditorPanel = require(script.UI.EditorPanel)
local Toolbar = require(script.UI.Toolbar)

type DialogNode = DialogTree.DialogNode

local ToolbarButton = plugin:CreateToolbar("YarnSpitter")
local Button = ToolbarButton:CreateButton("Open Editor", "Create and edit dialog trees using YarnSpitter", "rbxassetid://124231195330391")

local WidgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false,
	false,
	500,
	700,
	500,
	700
)

local Version = 1.31

warn("YarnSpitter V" ..  tostring(Version))

local Widget = plugin:CreateDockWidgetPluginGui("DialogTreeEditor", WidgetInfo)
Widget.Title = "YarnSpitter Editor Window"

local CurrentTree: DialogNode? = nil
local SelectedNode: DialogNode? = nil
local CurrentFileName: string = "UntitledDialog"
local NameBox: TextBox = nil

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.fromScale(1, 1)
MainFrame.BackgroundColor3 = Constants.COLORS.Background
MainFrame.Parent = Widget

local TreeScrollFrame: ScrollingFrame
local EditorScroll: ScrollingFrame

local function UpdateWindowTitle()
	Widget.Title = "YarnSpitter Editor - " .. CurrentFileName
end

local SelectNode

local function RefreshAll()
	TreeView.Refresh(TreeScrollFrame, CurrentTree, SelectedNode, SelectNode)
	EditorPanel.Refresh(EditorScroll, SelectedNode, RefreshAll, SelectNode)
end

SelectNode = function(Node: DialogNode)
	SelectedNode = Node
	RefreshAll()
end

local function CreateNewTree()
	CurrentTree = DialogTree.CreateNode("start", "Enter greeting text here...")
	SelectedNode = CurrentTree
	CurrentFileName = "UntitledDialog"
	if NameBox then
		NameBox.Text = CurrentFileName
	end
	UpdateWindowTitle()
	RefreshAll()
end

local function SaveTree()
	if not CurrentTree then
		warn("[Dialog Tree Plugin] No tree to save!")
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
		print("[Dialog Tree Plugin] Saved tree as:", CurrentFileName)
		UpdateWindowTitle()
	end
end

local function LoadTree()
	local DialogsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Dialogs")
	if not DialogsFolder then
		warn("[Dialog Tree Plugin] No Dialogs folder found!")
		return
	end

	local Modules = {}
	for _, Child in ipairs(DialogsFolder:GetChildren()) do
		if Child:IsA("ModuleScript") and Child:FindFirstChild("TreeData") then
			table.insert(Modules, Child.Name)
		end
	end

	if #Modules == 0 then
		warn("[Dialog Tree Plugin] No saved dialog trees found!")
		return
	end

	print("[Dialog Tree Plugin] Available dialogs:", table.concat(Modules, ", "))
	print("[Dialog Tree Plugin] Loading first available:", Modules[1])

	local ModuleToLoad = DialogsFolder:FindFirstChild(Modules[1])
	if ModuleToLoad then
		local LoadedTree = Serializer.LoadFromModule(ModuleToLoad)
		if LoadedTree then
			CurrentTree = LoadedTree
			SelectedNode = CurrentTree
			CurrentFileName = ModuleToLoad.Name
			if NameBox then
				NameBox.Text = CurrentFileName
			end
			UpdateWindowTitle()
			RefreshAll()
			print("[Dialog Tree Plugin] Loaded tree:", CurrentFileName)
		end
	end
end

local function GenerateCode()
	if not CurrentTree then
		warn("[Dialog Tree Plugin] No tree to generate!")
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
		print("[Dialog Tree Plugin] Generated dialog script successfully!")
		UpdateWindowTitle()
	else
		warn("[Dialog Tree Plugin] Failed to create module:", Result)
	end
end

local function OnNameChanged(NewName: string)
	if NewName ~= "" then
		CurrentFileName = NewName
		UpdateWindowTitle()
	end
end

local _, FileNameBox = Toolbar.Create(MainFrame, CreateNewTree, SaveTree, LoadTree, GenerateCode, OnNameChanged)
NameBox = FileNameBox
TreeScrollFrame = TreeView.Create(MainFrame)
EditorScroll = EditorPanel.Create(MainFrame)

Button.Click:Connect(function()
	Widget.Enabled = not Widget.Enabled
end)