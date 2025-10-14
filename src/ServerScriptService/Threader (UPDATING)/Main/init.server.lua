--!strict
local Plugin = plugin
local PluginBootstrap = require(script.Plugin.PluginBootstrap)
local PluginSettings = require(script.Plugin.PluginSettings)
local PluginCommands = require(script.Plugin.PluginCommands)
local MenuBar = require(script.Layout.MenuBar)
local ViewManager = require(script.Views.ViewManager)
local TreeView = require(script.Views.TreeView)
local NodeEditorView = require(script.Views.NodeEditorView)
local GraphView = require(script.Graph.GraphView)
local ResizableDivider = require(script.Layout.ResizableDivider)
local ModalView = require(script.Views.ModalView)
local FlagsManagerWindow = require(script.Windows.FlagsManagerWindow)
local UIStateManager = require(script.Managers.UIStateManager)
local HistoryManager = require(script.Managers.HistoryManager)
local ClipboardManager = require(script.Managers.ClipboardManager)

local Widget: DockWidgetPluginGui
local MainFrame: Frame
local TreeViewFrame: ScrollingFrame
local EditorViewFrame: ScrollingFrame
local GraphViewFrame: Frame
local CurrentTree: any? = nil
local CurrentFilename: string? = nil

local function RefreshAll()
	if not CurrentTree then return end

	if not TreeViewFrame or not EditorViewFrame then
		warn("[Threader] UI not initialized yet")
		return
	end

	TreeView.Refresh(TreeViewFrame, CurrentTree, function(Node)
		UIStateManager.SelectNode(Node)
		NodeEditorView.Refresh(EditorViewFrame, RefreshAll)
	end, function(Choice)
		UIStateManager.SelectChoice(Choice)
		NodeEditorView.Refresh(EditorViewFrame, RefreshAll)
	end)

	NodeEditorView.Refresh(EditorViewFrame, RefreshAll)

	if UIStateManager.GetCurrentView() == "Graph" then
		GraphView.Refresh(CurrentTree, function(Node)
			UIStateManager.SelectNode(Node)
			NodeEditorView.Refresh(EditorViewFrame, RefreshAll)
		end, function(Choice)
			UIStateManager.SelectChoice(Choice)
			NodeEditorView.Refresh(EditorViewFrame, RefreshAll)
		end)
	end
end

local function Initialize()
	Widget = PluginBootstrap.Initialize(Plugin)
	PluginSettings.Initialize(Plugin)

	MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = UDim2.fromScale(1, 1)
	MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	MainFrame.BorderSizePixel = 0
	MainFrame.Parent = Widget

	local Menus = {
		{
			Name = "File",
			Items = {
				{
					Text = "New",
					OnClick = function()
						if CurrentTree then
							ModalView.CreateConfirmation(
								MainFrame,
								"Create New Tree",
								"This will discard the current tree. Continue?",
								function()
									PluginCommands.NewTree(function(NewTree)
										CurrentTree = NewTree
										CurrentFilename = nil
										UIStateManager.SelectNode(NewTree)
										RefreshAll()
									end)
								end
							)
						else
							PluginCommands.NewTree(function(NewTree)
								CurrentTree = NewTree
								CurrentFilename = nil
								UIStateManager.SelectNode(NewTree)
								RefreshAll()
							end)
						end
					end
				},
				{
					Text = "Load",
					OnClick = function()
					end
				},
				{
					Text = "Save",
					OnClick = function()
						if CurrentTree and CurrentFilename then
							PluginCommands.SaveTree(CurrentTree, CurrentFilename)
							ModalView.CreateNotification(MainFrame, "Success", "Tree saved!")
						else
							ModalView.CreateNotification(MainFrame, "Error", "No tree to save")
						end
					end
				},
				{
					Text = "Generate Code",
					OnClick = function()
						if CurrentTree and CurrentFilename then
							PluginCommands.GenerateCode(CurrentTree, CurrentFilename)
							ModalView.CreateNotification(MainFrame, "Success", "Code generated!")
						else
							ModalView.CreateNotification(MainFrame, "Error", "No tree to generate")
						end
					end
				}
			}
		},
		{
			Name = "Edit",
			Items = {
				{
					Text = "Undo",
					OnClick = function()
						if HistoryManager.CanUndo() then
							HistoryManager.Undo()
							RefreshAll()
						end
					end
				},
				{
					Text = "Redo",
					OnClick = function()
						if HistoryManager.CanRedo() then
							HistoryManager.Redo()
							RefreshAll()
						end
					end
				},
				{Separator = true},
				{
					Text = "Copy",
					OnClick = function()
						local SelectedNode = UIStateManager.GetSelectedNode()
						if SelectedNode then
							ClipboardManager.CopyNode(SelectedNode)
							ModalView.CreateNotification(MainFrame, "Info", "Node copied", 1.5)
						end
					end
				},
				{
					Text = "Paste",
					OnClick = function()
						if ClipboardManager.CanPaste() then
							local Pasted = ClipboardManager.Paste()
							if Pasted then
								ModalView.CreateNotification(MainFrame, "Info", "Node pasted", 1.5)
							end
						end
					end
				}
			}
		},
		{
			Name = "View",
			Items = {
				{
					Text = "Editor Mode",
					OnClick = function()
						ViewManager.SwitchToView("Editor")
						RefreshAll()
					end
				},
				{
					Text = "Graph Mode",
					OnClick = function()
						ViewManager.SwitchToView("Graph")
						RefreshAll()
					end
				}
			}
		},
		{
			Name = "Tools",
			Items = {
				{
					Text = "Flags Manager",
					OnClick = function()
						FlagsManagerWindow.Open(MainFrame)
					end
				},
				{
					Text = "Validate Tree",
					OnClick = function()
						if not CurrentTree then
							ModalView.CreateNotification(MainFrame, "Error", "No tree to validate")
							return
						end

						local Validation = require(script.Core.Validation)
						local Result = Validation.ValidateTree(CurrentTree)

						if Result.IsValid then
							ModalView.CreateNotification(MainFrame, "Success", "Tree is valid!")
						else
							local ErrorMessage = "Validation errors:\n" .. table.concat(Result.Errors, "\n")
							warn(ErrorMessage)
							ModalView.CreateNotification(MainFrame, "Error", "Tree has validation errors (see output)")
						end
					end
				}
			}
		}
	}

	MenuBar.CreateMenuBar(MainFrame, Menus)

	TreeViewFrame = TreeView.Create(MainFrame)
	EditorViewFrame = NodeEditorView.Create(MainFrame)
	GraphViewFrame = GraphView.Initialize(MainFrame, Plugin)

	local Divider = ResizableDivider.Create(MainFrame, function(NewWidth)
		TreeViewFrame.Size = UDim2.new(0, NewWidth, 1, -30)
		EditorViewFrame.Size = UDim2.new(1, -NewWidth, 1, -30)
		EditorViewFrame.Position = UDim2.fromOffset(NewWidth, 30)
	end)

	ViewManager.Initialize(TreeViewFrame, EditorViewFrame, GraphViewFrame, MainFrame, Divider)

	PluginCommands.NewTree(function(NewTree)
		CurrentTree = NewTree
		UIStateManager.SelectNode(NewTree)
		RefreshAll()
	end)

	Widget:BindToClose(function()
		Widget.Enabled = false
	end)
end

Initialize()