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
local CurrentTree: any? = nil
local CurrentFilename: string? = nil

local function RefreshAll()
	if not CurrentTree then return end

	TreeView.Refresh(MainFrame:FindFirstChild("TreeView"), CurrentTree, function(Node)
		UIStateManager.SelectNode(Node)
		NodeEditorView.Refresh(MainFrame:FindFirstChild("EditorView"), RefreshAll)
	end, function(Choice)
		UIStateManager.SelectChoice(Choice)
		NodeEditorView.Refresh(MainFrame:FindFirstChild("EditorView"), RefreshAll)
	end)

	NodeEditorView.Refresh(MainFrame:FindFirstChild("EditorView"), RefreshAll)

	if UIStateManager.GetCurrentView() == "Graph" then
		GraphView.Refresh(CurrentTree, function(Node)
			UIStateManager.SelectNode(Node)
			NodeEditorView.Refresh(MainFrame:FindFirstChild("EditorView"), RefreshAll)
		end, function(Choice)
			UIStateManager.SelectChoice(Choice)
			NodeEditorView.Refresh(MainFrame:FindFirstChild("EditorView"), RefreshAll)
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
										HistoryManager.Clear()
										RefreshAll()
									end)
								end
							)
						else
							PluginCommands.NewTree(function(NewTree)
								CurrentTree = NewTree
								CurrentFilename = nil
								HistoryManager.Clear()
								RefreshAll()
							end)
						end
					end
				},
				{Separator = true},
				{
					Text = "Save",
					OnClick = function()
						if not CurrentTree then
							ModalView.CreateNotification(MainFrame, "Error", "No tree to save")
							return
						end

						if CurrentFilename then
							local Success = PluginCommands.SaveTree(CurrentTree, CurrentFilename)
							if Success then
								ModalView.CreateNotification(MainFrame, "Success", "Tree saved successfully")
							else
								ModalView.CreateNotification(MainFrame, "Error", "Failed to save tree")
							end
						else
							ModalView.CreateTextInput(
								MainFrame,
								"Save Tree",
								"Enter filename:",
								"MyDialog",
								function(Filename)
									local Success = PluginCommands.SaveTree(CurrentTree, Filename)
									if Success then
										CurrentFilename = Filename
										ModalView.CreateNotification(MainFrame, "Success", "Tree saved as " .. Filename)
									else
										ModalView.CreateNotification(MainFrame, "Error", "Failed to save tree")
									end
								end
							)
						end
					end
				},
				{
					Text = "Save As...",
					OnClick = function()
						if not CurrentTree then
							ModalView.CreateNotification(MainFrame, "Error", "No tree to save")
							return
						end

						ModalView.CreateTextInput(
							MainFrame,
							"Save Tree As",
							"Enter filename:",
							CurrentFilename or "MyDialog",
							function(Filename)
								local Success = PluginCommands.SaveTree(CurrentTree, Filename)
								if Success then
									CurrentFilename = Filename
									ModalView.CreateNotification(MainFrame, "Success", "Tree saved as " .. Filename)
								else
									ModalView.CreateNotification(MainFrame, "Error", "Failed to save tree")
								end
							end
						)
					end
				},
				{
					Text = "Load...",
					OnClick = function()
						local SavedTrees = PluginCommands.GetAllSavedTrees()
						if #SavedTrees == 0 then
							ModalView.CreateNotification(MainFrame, "Info", "No saved trees found")
							return
						end

						local LoadWindow = require(script.Windows.LoadWindow)
						LoadWindow.Open(MainFrame, SavedTrees, function(Filename)
							local LoadedTree = PluginCommands.LoadTree(Filename)
							if LoadedTree then
								CurrentTree = LoadedTree
								CurrentFilename = Filename
								HistoryManager.Clear()
								RefreshAll()
								ModalView.CreateNotification(MainFrame, "Success", "Tree loaded: " .. Filename)
							else
								ModalView.CreateNotification(MainFrame, "Error", "Failed to load tree")
							end
						end)
					end
				},
				{Separator = true},
				{
					Text = "Generate Code",
					OnClick = function()
						if not CurrentTree then
							ModalView.CreateNotification(MainFrame, "Error", "No tree to generate")
							return
						end

						local Filename = CurrentFilename or "GeneratedDialog"
						local Module = PluginCommands.GenerateCode(CurrentTree, Filename)
						if Module then
							ModalView.CreateNotification(MainFrame, "Success", "Code generated in ReplicatedStorage/Dialogs")
						else
							ModalView.CreateNotification(MainFrame, "Error", "Failed to generate code")
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

	local TreeViewFrame = TreeView.Create(MainFrame)
	local EditorViewFrame = NodeEditorView.Create(MainFrame)
	local GraphViewFrame = GraphView.Initialize(MainFrame, Plugin)

	local Divider = ResizableDivider.Create(MainFrame, function(NewWidth)
		TreeViewFrame.Size = UDim2.new(0, NewWidth, 1, -30)
		EditorViewFrame.Size = UDim2.new(1, -NewWidth, 1, -30)
		EditorViewFrame.Position = UDim2.new(0, NewWidth, 0, 30)
		--Divider.Position = UDim2.new(0, NewWidth, 0, 30)
	end)

	ViewManager.Initialize(TreeViewFrame, EditorViewFrame, GraphViewFrame, MainFrame, Divider)

	PluginCommands.NewTree(function(NewTree)
		CurrentTree = NewTree
		RefreshAll()
	end)

	Widget:BindToClose(function()
		Widget.Enabled = false
	end)
end

Initialize()