--!strict
local DialogConditions = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(Modules:WaitForChild("QuestManager"))

export type Condition = {
	Type: string,
	Value: any,
	Negate: boolean?
}

local ConditionChecks = {}

function ConditionChecks.HasQuest(Player: Player, QuestId: string): boolean
	return QuestManager.HasActiveQuest(Player, QuestId)
end

function ConditionChecks.CompletedQuest(Player: Player, QuestId: string): boolean
	return QuestManager.HasCompletedQuest(Player, QuestId)
end

function ConditionChecks.CanTurnInQuest(Player: Player, QuestId: string): boolean
	local Quest = QuestManager.GetActiveQuest(Player, QuestId)
	if not Quest then return false end

	for _, Objective in ipairs(Quest.Objectives) do
		if not Objective.Completed then
			return false
		end
	end

	return true
end

function ConditionChecks.HasReputation(Player: Player, Data: {Faction: string, Min: number}): boolean
	local Rep = Player:GetAttribute("Reputation_" .. Data.Faction) or 0
	return Rep >= Data.Min
end

function ConditionChecks.HasAttribute(Player: Player, Data: {Name: string, Min: number}): boolean
	local Value = Player:GetAttribute(Data.Name) or 0
	return Value >= Data.Min
end

function ConditionChecks.HasItem(Player: Player, ItemId: string): boolean
	local Backpack = Player:FindFirstChild("Backpack")
	if Backpack and Backpack:FindFirstChild(ItemId) then
		return true
	end

	local Character = Player.Character
	if Character and Character:FindFirstChild(ItemId) then
		return true
	end

	return false
end

function ConditionChecks.Level(Player: Player, MinLevel: number): boolean
	local Level = Player:GetAttribute("Level") or 1
	return Level >= MinLevel
end

function ConditionChecks.HasSkill(Player: Player, Data: {Skill: string, Min: number}): boolean
	local SkillValue = Player:GetAttribute("Skill_" .. Data.Skill) or 0
	return SkillValue >= Data.Min
end

function ConditionChecks.DialogFlag(Player: Player, FlagName: string): boolean
	return Player:GetAttribute("DialogFlag_" .. FlagName) == true
end

function ConditionChecks.Custom(Player: Player, CheckFunction: (Player) -> boolean): boolean
	return CheckFunction(Player)
end

function DialogConditions.Check(Player: Player, Condition: Condition): boolean
	local CheckFunc = ConditionChecks[Condition.Type]
	if not CheckFunc then
		warn("[DialogConditions] Unknown condition type:", Condition.Type)
		return false
	end

	local Result = CheckFunc(Player, Condition.Value)

	if Condition.Negate then
		return not Result
	end

	return Result
end

function DialogConditions.CheckAll(Player: Player, Conditions: {Condition}?): boolean
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
	Player:SetAttribute("DialogFlag_" .. FlagName, Value ~= false)
end

return DialogConditions