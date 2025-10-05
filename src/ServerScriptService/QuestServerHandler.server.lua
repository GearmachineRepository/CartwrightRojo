--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(Modules:WaitForChild("QuestManager"))

local Events = ReplicatedStorage:WaitForChild("Events")
local QuestEvents = Events:WaitForChild("QuestEvents")
local GiveQuestRemote = QuestEvents:WaitForChild("GiveQuest") :: RemoteEvent

GiveQuestRemote.OnServerEvent:Connect(function(Player: Player, QuestId: string)
	if typeof(QuestId) ~= "string" then return end

	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	if PlayerData.ActiveQuests[QuestId] then
		return
	end

	if PlayerData.CompletedQuests[QuestId] then
		return
	end

	local ActiveCount = 0
	for _ in pairs(PlayerData.ActiveQuests) do
		ActiveCount += 1
	end

	if ActiveCount >= 5 then
		return
	end

	QuestManager.GiveQuest(Player, QuestId)
end)

print("[QuestServerHandler] Quest server handler initialized")