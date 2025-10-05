--!strict
local DialogHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local DialogText = require(ModulesFolder:WaitForChild("DialogText"))

type DialogNode = {
	Id: string,
	Text: string,
	Choices: {{Text: string, Response: DialogNode, Command: ((Player) -> ())? }}?
}

local function GetTextList(Choices: {{Text: string, Response: DialogNode, Command: ((Player) -> ())? }}): {string}
	local List = {}
	for _, Choice in ipairs(Choices) do
		table.insert(List, Choice.Text)
	end
	return List
end

local function ShowNode(Node: DialogNode, Player: Player, NpcModel: Model, OnFinished: (() -> ())?): ()
	DialogText.NpcText(NpcModel, Node.Text, true)

	if Node.Choices then
		local Options = GetTextList(Node.Choices)
		local Buttons = DialogText.ShowChoices(Player, Options)

		local SelectedText = ""
		local Connections = {}

		for _, Button in pairs(Buttons) do
			local Frame = Button:FindFirstChild("Frame")
			if Frame and Frame:FindFirstChild("ImageButton") then
				table.insert(Connections, Frame.ImageButton.MouseButton1Click:Connect(function()
					SelectedText = Frame.Frame.Text_Element:GetAttribute("Text")
				end))
			end
		end

		repeat task.wait() until SelectedText ~= ""

		for _, Connection in ipairs(Connections) do
			Connection:Disconnect()
		end

		DialogText.RemovePlayerSideFrame(Player)
		DialogText.PlayerResponse(Player.Character, SelectedText, true)
		task.wait(0.5)

		for _, Choice in ipairs(Node.Choices) do
			if Choice.Text == SelectedText then
				if typeof(Choice.Command) == "function" then
					pcall(function()
						Choice.Command(Player)
					end)
				end
				ShowNode(Choice.Response, Player, NpcModel, OnFinished)
				return
			end
		end
	else
		task.wait(2)
		DialogText.TakeAwayResponses(NpcModel, Player)
		if typeof(OnFinished) == "function" then
			OnFinished()
		end
	end
end

function DialogHandler.Start(NpcModel: Model, Player: Player, OnFinished: (() -> ())?): ()
	local NpcName = NpcModel.Name
	local DialogModule = ReplicatedStorage:WaitForChild("Dialogs"):FindFirstChild(NpcName)

	if DialogModule and DialogModule:IsA("ModuleScript") then
		local Loaded = require(DialogModule)

		local Tree: DialogNode?
		if typeof(Loaded) == "function" then
			local Success, Result = pcall(Loaded, Player)
			if Success and typeof(Result) == "table" then
				Tree = Result
			else
				warn("DialogHandler: Failed to generate tree for " .. NpcName)
			end
		elseif typeof(Loaded) == "table" then
			Tree = Loaded
		end

		if Tree then
			ShowNode(Tree, Player, NpcModel, OnFinished)
		else
			warn("DialogHandler: No valid dialog tree for " .. NpcName)
			if typeof(OnFinished) == "function" then
				OnFinished()
			end
		end
	else
		warn("DialogHandler: No dialog module found for NPC: " .. NpcName)
		if typeof(OnFinished) == "function" then
			OnFinished()
		end
	end
end

return DialogHandler