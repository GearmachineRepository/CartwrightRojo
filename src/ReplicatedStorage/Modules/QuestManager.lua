--!strict
local QuestManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local IsServer = RunService:IsServer()
local IsClient = RunService:IsClient()

local Events = ReplicatedStorage:WaitForChild("Events")
local QuestEvents = Events:WaitForChild("QuestEvents")
local UpdateQuestRemote = QuestEvents:WaitForChild("UpdateQuest") :: RemoteEvent
local QuestStateChangedRemote = QuestEvents:WaitForChild("QuestStateChanged") :: RemoteEvent

local QuestDefinitions = ReplicatedStorage:WaitForChild("QuestDefinitions")

local MAX_ACTIVE_QUESTS = 5

export type QuestObjective = {
	Description: string,
	Type: string,
	TargetId: string?,
	TargetPosition: Vector3?,
	RequiredAmount: number,
	CurrentAmount: number,
	Completed: boolean,
	Trackable: boolean?
}

export type Quest = {
	Id: string,
	Title: string,
	Description: string,
	Objectives: {QuestObjective},
	Rewards: {[string]: any}?,
	Pinned: boolean,
	CompletedTime: number?,
	RequiresTurnIn: boolean?,
	TurnInNpc: string?,
	ReadyToTurnIn: boolean?
}

type PlayerQuestData = {
	ActiveQuests: {[string]: Quest},
	CompletedQuests: {[string]: boolean}
}

local PlayerQuests: {[Player]: PlayerQuestData} = {}
local ClientQuests: PlayerQuestData? = nil

local function LoadQuestDefinition(QuestId: string): Quest?
	local QuestModule = QuestDefinitions:FindFirstChild(QuestId)
	if not QuestModule or not QuestModule:IsA("ModuleScript") then
		return nil
	end

	local Success, QuestData = pcall(require, QuestModule)
	if not Success then
		warn("Failed to load quest definition:", QuestId)
		return nil
	end

	return QuestData
end

function QuestManager.InitializePlayer(Player: Player): ()
	if not IsServer then return end

	PlayerQuests[Player] = {
		ActiveQuests = {},
		CompletedQuests = {}
	}
end

function QuestManager.GetPlayerData(Player: Player): PlayerQuestData?
	if IsClient then
		return ClientQuests
	end
	return PlayerQuests[Player]
end

function QuestManager.GiveQuest(Player: Player, QuestId: string): boolean
	if not IsServer then return false end

	local Data = PlayerQuests[Player]
	if not Data then return false end

	if Data.ActiveQuests[QuestId] then
		return false
	end

	if Data.CompletedQuests[QuestId] then
		return false
	end

	local ActiveCount = 0
	for _ in pairs(Data.ActiveQuests) do
		ActiveCount += 1
	end

	if ActiveCount >= MAX_ACTIVE_QUESTS then
		return false
	end

	local QuestDefinition = LoadQuestDefinition(QuestId)
	if not QuestDefinition then
		return false
	end

	local NewQuest: Quest = {
		Id = QuestId,
		Title = QuestDefinition.Title,
		Description = QuestDefinition.Description,
		Objectives = {},
		Rewards = QuestDefinition.Rewards,
		Pinned = true,
		RequiresTurnIn = QuestDefinition.RequiresTurnIn,
		TurnInNpc = QuestDefinition.TurnInNpc,
		ReadyToTurnIn = false
	}

	for _, ObjectiveDef in ipairs(QuestDefinition.Objectives) do
		table.insert(NewQuest.Objectives, {
			Description = ObjectiveDef.Description,
			Type = ObjectiveDef.Type,
			TargetId = ObjectiveDef.TargetId,
			TargetPosition = ObjectiveDef.TargetPosition,
			RequiredAmount = ObjectiveDef.RequiredAmount,
			CurrentAmount = 0,
			Completed = false,
			Trackable = ObjectiveDef.Trackable
		})
	end

	Data.ActiveQuests[QuestId] = NewQuest
	QuestStateChangedRemote:FireClient(Player, "QuestAdded", NewQuest)

	task.defer(function()
		for _, Objective in ipairs(NewQuest.Objectives) do
			if Objective.Type == "Deliver" and Objective.TargetId then
				local Backpack = Player:FindFirstChild("Backpack")
				local Character = Player.Character
				local ItemCount = 0

				if Backpack then
					for _, Item in ipairs(Backpack:GetChildren()) do
						if Item.Name == Objective.TargetId then
							ItemCount += 1
						end
					end
				end

				if Character then
					for _, Item in ipairs(Character:GetChildren()) do
						if Item.Name == Objective.TargetId then
							ItemCount += 1
						end
					end
				end

				if ItemCount > 0 then
					local AmountToAdd = math.min(ItemCount, Objective.RequiredAmount)
					QuestManager.UpdateQuestProgress(Player, QuestId, "Deliver", Objective.TargetId, AmountToAdd)
				end
			end
		end
	end)

	return true
end

function QuestManager.UpdateQuestProgress(Player: Player, QuestId: string, ObjectiveType: string, TargetId: string?, Amount: number): ()
	if not IsServer then return end

	local Data = PlayerQuests[Player]
	if not Data then return end

	local Quest = Data.ActiveQuests[QuestId]
	if not Quest then return end

	local QuestCompleted = true

	for _, Objective in ipairs(Quest.Objectives) do
		if Objective.Type == ObjectiveType and Objective.TargetId == TargetId then
			Objective.CurrentAmount = math.min(Objective.CurrentAmount + Amount, Objective.RequiredAmount)

			if Objective.CurrentAmount >= Objective.RequiredAmount then
				Objective.Completed = true
			end

			UpdateQuestRemote:FireClient(Player, QuestId, Quest.Objectives)
		end

		if not Objective.Completed then
			QuestCompleted = false
		end
	end

	if QuestCompleted then
		if Quest.RequiresTurnIn then
			Quest.ReadyToTurnIn = true
			QuestStateChangedRemote:FireClient(Player, "QuestReadyToTurnIn", Quest)
			UpdateQuestRemote:FireClient(Player, QuestId, Quest.Objectives, Quest.ReadyToTurnIn, Quest.TurnInNpc)
		else
			QuestManager.CompleteQuest(Player, QuestId)
		end
	else
		UpdateQuestRemote:FireClient(Player, QuestId, Quest.Objectives, Quest.ReadyToTurnIn, Quest.TurnInNpc)
	end
end

function QuestManager.TurnInQuest(Player: Player, QuestId: string): boolean
	if not IsServer then return false end

	local Data = PlayerQuests[Player]
	if not Data then
		warn("[QuestManager] No player data")
		return false
	end

	local Quest = Data.ActiveQuests[QuestId]
	if not Quest then
		warn("[QuestManager] Quest not found in active quests")
		return false
	end

	if not Quest.ReadyToTurnIn then
		return false
	end

	for _, Objective in ipairs(Quest.Objectives) do
		if Objective.Type == "Deliver" and Objective.TargetId then
			local RemovedCount = 0
			local Backpack = Player:FindFirstChild("Backpack")
			local Character = Player.Character

			while RemovedCount < Objective.RequiredAmount do
				local ItemRemoved = false

				if Backpack then
					local Item = Backpack:FindFirstChild(Objective.TargetId)
					if Item then
						Item:Destroy()
						RemovedCount += 1
						ItemRemoved = true
					end
				end

				if not ItemRemoved and Character then
					local Item = Character:FindFirstChild(Objective.TargetId)
					if Item then
						Item:Destroy()
						RemovedCount += 1
						ItemRemoved = true
					end
				end

				if not ItemRemoved then
					break
				end
			end
		end
	end

	QuestManager.CompleteQuest(Player, QuestId)
	return true
end

function QuestManager.CompleteQuest(Player: Player, QuestId: string): ()
	if not IsServer then return end

	local Data = PlayerQuests[Player]
	if not Data then return end

	local Quest = Data.ActiveQuests[QuestId]
	if not Quest then return end

	Quest.CompletedTime = os.time()
	Data.CompletedQuests[QuestId] = true
	Data.ActiveQuests[QuestId] = nil

	QuestStateChangedRemote:FireClient(Player, "QuestCompleted", Quest)
end

function QuestManager.HasActiveQuest(Player: Player, QuestId: string): boolean
	local Data = PlayerQuests[Player]
	if not Data then return false end

	return Data.ActiveQuests[QuestId] ~= nil
end

function QuestManager.GetActiveQuest(Player: Player, QuestId: string): Quest?
	local Data = PlayerQuests[Player]
	if not Data then return nil end

	return Data.ActiveQuests[QuestId]
end

function QuestManager.HasCompletedQuest(Player: Player, QuestId: string): boolean
	local Data = PlayerQuests[Player]
	if not Data then return false end

	return Data.CompletedQuests[QuestId] == true
end

function QuestManager.GetActivePinnedQuests(Player: Player): {Quest}
	local Data = PlayerQuests[Player]
	if not Data then return {} end

	local PinnedQuests = {}
	for _, Quest in pairs(Data.ActiveQuests) do
		if Quest.Pinned then
			table.insert(PinnedQuests, Quest)
		end
	end

	return PinnedQuests
end

function QuestManager.ToggleQuestPin(Player: Player, QuestId: string): ()
	if not IsServer then return end

	local Data = PlayerQuests[Player]
	if not Data then return end

	local Quest = Data.ActiveQuests[QuestId]
	if not Quest then return end

	Quest.Pinned = not Quest.Pinned
	QuestStateChangedRemote:FireClient(Player, "QuestUpdated", Quest)
end

function QuestManager.Cleanup(Player: Player): ()
	PlayerQuests[Player] = nil
end

if IsServer then
	Players.PlayerAdded:Connect(QuestManager.InitializePlayer)
	Players.PlayerRemoving:Connect(QuestManager.Cleanup)
elseif IsClient then
	ClientQuests = {
		ActiveQuests = {},
		CompletedQuests = {}
	}

	QuestStateChangedRemote.OnClientEvent:Connect(function(Action: string, Quest: Quest)
		if not ClientQuests then return end

		if Action == "QuestAdded" then
			ClientQuests.ActiveQuests[Quest.Id] = Quest
		elseif Action == "QuestCompleted" then
			ClientQuests.CompletedQuests[Quest.Id] = true
			ClientQuests.ActiveQuests[Quest.Id] = nil
		elseif Action == "QuestUpdated" then
			if ClientQuests.ActiveQuests[Quest.Id] then
				ClientQuests.ActiveQuests[Quest.Id] = Quest
			end
		end
	end)

	UpdateQuestRemote.OnClientEvent:Connect(function(QuestId: string, Objectives: {QuestObjective})
		if not ClientQuests then return end
		local Quest = ClientQuests.ActiveQuests[QuestId]
		if Quest then
			Quest.Objectives = Objectives
		end
	end)
end

return QuestManager