--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(Modules:WaitForChild("QuestManager"))

local Events = ReplicatedStorage:WaitForChild("Events")
local QuestEvents = Events:WaitForChild("QuestEvents")
local TaskCompletedRemote = QuestEvents:WaitForChild("TaskCompleted") :: RemoteEvent

local TaskHandlers = {}

function TaskHandlers.Collect(Player: Player, ItemId: string, Amount: number): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	for QuestId, _ in pairs(PlayerData.ActiveQuests) do
		QuestManager.UpdateQuestProgress(Player, QuestId, "Collect", ItemId, Amount)
	end
end

function TaskHandlers.Interact(Player: Player, ObjectId: string): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	for QuestId, _ in pairs(PlayerData.ActiveQuests) do
		QuestManager.UpdateQuestProgress(Player, QuestId, "Interact", ObjectId, 1)
	end
end

function TaskHandlers.Kill(Player: Player, EnemyId: string, Amount: number): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	for QuestId, _ in pairs(PlayerData.ActiveQuests) do
		QuestManager.UpdateQuestProgress(Player, QuestId, "Kill", EnemyId, Amount)
	end
end

function TaskHandlers.Deliver(Player: Player, ItemId: string, _: string): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	for QuestId, _ in pairs(PlayerData.ActiveQuests) do
		QuestManager.UpdateQuestProgress(Player, QuestId, "Deliver", ItemId, 1)
	end
end

function TaskHandlers.TalkTo(Player: Player, NpcId: string): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	for QuestId, _ in pairs(PlayerData.ActiveQuests) do
		QuestManager.UpdateQuestProgress(Player, QuestId, "TalkTo", NpcId, 1)
	end
end

TaskCompletedRemote.OnServerEvent:Connect(function(Player: Player, TaskType: string, TargetId: string, Amount: number?)
	local Handler = TaskHandlers[TaskType]
	if Handler then
		Handler(Player, TargetId, Amount or 1)
	else
		warn("[QuestTaskHandler] Unknown task type:", TaskType)
	end
end)

print("[QuestTaskHandler] Quest task handler initialized")