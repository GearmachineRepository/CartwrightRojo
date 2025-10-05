--!strict
local DialogConditions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogDataManager = require(Modules:WaitForChild("DialogDataManager"))
local QuestManager = require(Modules:WaitForChild("QuestManager"))

export type Condition = {
	Type: string,
	Value: any,
	Negate: boolean?
}

function DialogConditions.Check(Player: Player, Condition: Condition): boolean
	local Result = false

	if Condition.Type == "DialogFlag" then
		Result = DialogDataManager.HasDialogFlag(Player, Condition.Value)
	elseif Condition.Type == "HasQuest" then
		Result = QuestManager.HasActiveQuest(Player, Condition.Value)
	elseif Condition.Type == "CompletedQuest" then
		Result = QuestManager.HasCompletedQuest(Player, Condition.Value)
	elseif Condition.Type == "CanTurnInQuest" then
		Result = QuestManager.CanTurnIn(Player, Condition.Value)
	elseif Condition.Type == "HasReputation" then
		if type(Condition.Value) == "table" then
			local Faction = Condition.Value.Faction
			local MinRep = Condition.Value.Min or 0
			local CurrentRep = Player:GetAttribute("Reputation_" .. Faction) or 0
			Result = CurrentRep >= MinRep
		end
	elseif Condition.Type == "HasSkill" then
		if type(Condition.Value) == "table" then
			local Skill = Condition.Value.Skill
			local MinLevel = Condition.Value.Min or 0
			local CurrentLevel = Player:GetAttribute("Skill_" .. Skill) or 0
			Result = CurrentLevel >= MinLevel
		end
	elseif Condition.Type == "HasItem" then
		local Backpack = Player:FindFirstChild("Backpack")
		if Backpack then
			Result = Backpack:FindFirstChild(Condition.Value) ~= nil
		end
	elseif Condition.Type == "HasAttribute" then
		if type(Condition.Value) == "table" then
			local AttributeName = Condition.Value.Name
			local RequiredValue = Condition.Value.Value
			local CurrentValue = Player:GetAttribute(AttributeName)

			if RequiredValue ~= nil then
				Result = CurrentValue == RequiredValue
			else
				Result = CurrentValue ~= nil
			end
		end
	end

	if Condition.Negate then
		return not Result
	end

	return Result
end

function DialogConditions.CheckAll(Player: Player, Conditions: {Condition}): boolean
	if not Conditions or #Conditions == 0 then
		return true
	end

	for _, Condition in ipairs(Conditions) do
		if not DialogConditions.Check(Player, Condition) then
			return false
		end
	end

	return true
end

function DialogConditions.CheckAny(Player: Player, Conditions: {Condition}): boolean
	if not Conditions or #Conditions == 0 then
		return false
	end

	for _, Condition in ipairs(Conditions) do
		if DialogConditions.Check(Player, Condition) then
			return true
		end
	end

	return false
end

function DialogConditions.SetFlag(Player: Player, FlagName: string, Value: boolean?): ()
	DialogDataManager.SetDialogFlag(Player, FlagName, Value ~= false)
end

return DialogConditions