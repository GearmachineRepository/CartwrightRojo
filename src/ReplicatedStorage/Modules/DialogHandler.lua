--!strict
local DialogHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(ModulesFolder:WaitForChild("QuestManager"))
local AdvancedDialogBuilder = require(ModulesFolder:WaitForChild("AdvancedDialogBuilder"))

local Events = ReplicatedStorage:WaitForChild("Events")
local DialogEvents = Events:WaitForChild("DialogEvents")
local GuiEvents = Events:WaitForChild("GuiEvents")

local ShowDialogRemote = DialogEvents:WaitForChild("ShowDialog") :: RemoteEvent
local DialogChoiceRemote = DialogEvents:WaitForChild("DialogChoice") :: RemoteEvent
local OpenGuiRemote = GuiEvents:WaitForChild("OpenGui") :: RemoteEvent

local IsServer = RunService:IsServer()

type DialogNode = {
	Id: string,
	Text: string,
	Choices: {{Text: string, Response: DialogNode, Command: ((Player) -> ())?}}?,
	OpenGui: string?,
	GiveQuest: string?,
	TurnInQuest: string?
}

type DialogSession = {
	Player: Player,
	NpcModel: Model,
	CurrentNode: DialogNode,
	DialogTree: DialogNode,
	OnFinished: (() -> ())?
}

local ActiveSessions: {[Player]: DialogSession} = {}

local function GetChoiceTexts(Choices: {{Text: string, Response: DialogNode, Command: ((Player) -> ())?}}): {string}
	local Texts = {}
	for _, Choice in ipairs(Choices) do
		table.insert(Texts, Choice.Text)
	end
	return Texts
end

local function HandleNodeActions(Node: DialogNode, Player: Player): ()
	if Node.OpenGui then
		OpenGuiRemote:FireClient(Player, Node.OpenGui)
	end

	if Node.TurnInQuest then
		QuestManager.TurnInQuest(Player, Node.TurnInQuest)
	end
end

local function ShowNodeToClient(Session: DialogSession, Node: DialogNode): ()
	Session.CurrentNode = Node

	local ProcessedNode = AdvancedDialogBuilder.ProcessNode(Session.Player, Node)

	HandleNodeActions(ProcessedNode, Session.Player)

	if ProcessedNode.GiveQuest then
		local PlayerData = QuestManager.GetPlayerData(Session.Player)
		if not PlayerData then
			ShowDialogRemote:FireClient(Session.Player, Session.NpcModel, ProcessedNode.Text, nil, true)
			ActiveSessions[Session.Player] = nil
			if typeof(Session.OnFinished) == "function" then
				Session.OnFinished()
			end
			return
		end

		if PlayerData.ActiveQuests[ProcessedNode.GiveQuest] or PlayerData.CompletedQuests[ProcessedNode.GiveQuest] then
			ShowDialogRemote:FireClient(Session.Player, Session.NpcModel, ProcessedNode.Text, nil, true)
			ActiveSessions[Session.Player] = nil
			if typeof(Session.OnFinished) == "function" then
				Session.OnFinished()
			end
			return
		end

		local ActiveCount = 0
		for _ in pairs(PlayerData.ActiveQuests) do
			ActiveCount += 1
		end

		if ActiveCount >= 5 then
			ShowDialogRemote:FireClient(Session.Player, Session.NpcModel, "Your quest log is full! Come back when you have space.", nil, true)
			ActiveSessions[Session.Player] = nil
			if typeof(Session.OnFinished) == "function" then
				Session.OnFinished()
			end
			return
		end

		local AcceptNode: DialogNode = {
			Id = "quest_confirmation",
			Text = "Will you accept this quest?",
			Choices = {
				{
					Text = "Accept",
					Response = {
						Id = "quest_accepted",
						Text = "Excellent! Good luck!"
					},
					Command = function(Plr: Player)
						QuestManager.GiveQuest(Plr, ProcessedNode.GiveQuest :: string)
					end
				},
				{
					Text = "Deny",
					Response = {
						Id = "quest_denied",
						Text = "No worries. The offer stands if you change your mind."
					}
				}
			}
		}

		ShowNodeToClient(Session, AcceptNode)
		return
	end

	if ProcessedNode.Choices then
		local ChoiceTexts = GetChoiceTexts(ProcessedNode.Choices)

		if #ChoiceTexts == 0 then
			ShowDialogRemote:FireClient(Session.Player, Session.NpcModel, ProcessedNode.Text, nil, true)
			ActiveSessions[Session.Player] = nil
			if typeof(Session.OnFinished) == "function" then
				Session.OnFinished()
			end
			return
		end
		ShowDialogRemote:FireClient(Session.Player, Session.NpcModel, ProcessedNode.Text, ChoiceTexts, false)
	else
		ShowDialogRemote:FireClient(Session.Player, Session.NpcModel, ProcessedNode.Text, nil, true)
		ActiveSessions[Session.Player] = nil
		if typeof(Session.OnFinished) == "function" then
			Session.OnFinished()
		end
	end
end

function DialogHandler.Start(NpcModel: Model, Player: Player, OnFinished: (() -> ())?): ()
	if not IsServer then return end

	if ActiveSessions[Player] then
		warn("[DialogHandler] Player already in dialog")
		return
	end

	local NpcName = NpcModel.Name
	local DialogModule = ReplicatedStorage:WaitForChild("Dialogs"):FindFirstChild(NpcName)

	if not DialogModule or not DialogModule:IsA("ModuleScript") then
		warn("[DialogHandler] No dialog module found for NPC:", NpcName)
		if typeof(OnFinished) == "function" then
			OnFinished()
		end
		return
	end

	local Success, Loaded = pcall(require, DialogModule)
	if not Success then
		warn("[DialogHandler] Failed to load dialog for", NpcName)
		if typeof(OnFinished) == "function" then
			OnFinished()
		end
		return
	end

	local Tree: DialogNode?
	if typeof(Loaded) == "function" then
		local FuncSuccess, Result = pcall(Loaded, Player)
		if FuncSuccess and typeof(Result) == "table" then
			Tree = Result
		else
			warn("[DialogHandler] Failed to generate tree for", NpcName)
		end
	elseif typeof(Loaded) == "table" then
		Tree = Loaded
	end

	if not Tree then
		warn("[DialogHandler] No valid dialog tree for", NpcName)
		if typeof(OnFinished) == "function" then
			OnFinished()
		end
		return
	end

	local Session: DialogSession = {
		Player = Player,
		NpcModel = NpcModel,
		CurrentNode = Tree,
		DialogTree = Tree,
		OnFinished = OnFinished
	}

	ActiveSessions[Player] = Session
	ShowNodeToClient(Session, Tree)
end

function DialogHandler.HandleChoice(Player: Player, ChoiceText: string): ()
	if not IsServer then return end

	local Session = ActiveSessions[Player]
	if not Session then return end

	local CurrentNode = Session.CurrentNode
	if not CurrentNode.Choices then return end

	for _, Choice in ipairs(CurrentNode.Choices) do
		if Choice.Text == ChoiceText then
			if typeof(Choice.Command) == "function" then
				pcall(function()
					Choice.Command(Player)
				end)
			end

			ShowNodeToClient(Session, Choice.Response)
			return
		end
	end
end

function DialogHandler.EndDialog(Player: Player): ()
	if not IsServer then return end

	local Session = ActiveSessions[Player]
	if Session then
		ActiveSessions[Player] = nil
		if typeof(Session.OnFinished) == "function" then
			Session.OnFinished()
		end
	end
end

if IsServer then
	DialogChoiceRemote.OnServerEvent:Connect(function(Player: Player, ChoiceText: string)
		DialogHandler.HandleChoice(Player, ChoiceText)
	end)

	local Players = game:GetService("Players")
	Players.PlayerRemoving:Connect(function(Player)
		DialogHandler.EndDialog(Player)
	end)
end

return DialogHandler