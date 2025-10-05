--!strict
local QuestProgressHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(Modules:WaitForChild("QuestManager"))

function QuestProgressHandler.OnItemPickup(Player: Player, ItemName: string): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then
		print("[QuestProgressHandler] No player data")
		return
	end

	task.wait(0.1)

	for QuestId, Quest in pairs(PlayerData.ActiveQuests) do
		for _, Objective in ipairs(Quest.Objectives) do
			if Objective.TargetId == ItemName and not Objective.Completed then
				if Objective.Type == "Collect" then
					QuestManager.UpdateQuestProgress(Player, QuestId, "Collect", ItemName, 1)
				elseif Objective.Type == "Deliver" then
					task.spawn(function()
						task.wait(0.2)

						local Backpack = Player:FindFirstChild("Backpack")
						local Character = Player.Character
						local HasItem = false

						if (Backpack and Backpack:FindFirstChild(ItemName)) or (Character and Character:FindFirstChild(ItemName)) then
							HasItem = true
						end

						if HasItem then
							QuestManager.UpdateQuestProgress(Player, QuestId, "Deliver", ItemName, 1)
						end
					end)
				end
			end
		end
	end
end

function QuestProgressHandler.OnEnemyKilled(Player: Player, EnemyName: string): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	for QuestId, _ in pairs(PlayerData.ActiveQuests) do
		QuestManager.UpdateQuestProgress(Player, QuestId, "Kill", EnemyName, 1)
	end
end

function QuestProgressHandler.OnNpcTalk(Player: Player, NpcName: string): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	for QuestId, _ in pairs(PlayerData.ActiveQuests) do
		QuestManager.UpdateQuestProgress(Player, QuestId, "TalkTo", NpcName, 1)
	end
end

function QuestProgressHandler.OnObjectInteract(Player: Player, ObjectName: string): ()
	local PlayerData = QuestManager.GetPlayerData(Player)
	if not PlayerData then return end

	for QuestId, _ in pairs(PlayerData.ActiveQuests) do
		QuestManager.UpdateQuestProgress(Player, QuestId, "Interact", ObjectName, 1)
	end
end

return QuestProgressHandler