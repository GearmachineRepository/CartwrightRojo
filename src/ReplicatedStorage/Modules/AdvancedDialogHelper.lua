--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local AdvancedDialogBuilder = require(Modules:WaitForChild("AdvancedDialogBuilder"))
local DialogDataManager = require(Modules:WaitForChild("DialogDataManager"))

export type Skills =
	"Perception" |
	"Empathy" |
	"Logic" |
	"Authority" |
	"Rhetoric" |
	"Composure" |
	"Endurance" |
	"Streetwise"

local Advanced = {}

function Advanced.CreateSkillCheck(Options: {
	Skill: Skills,
	Difficulty: number,
	ButtonText: string,
	SuccessResponse: string,
	SuccessChoices: {any}?,
	SuccessFlags: {string}?,
	SuccessCommand: ((Player) -> ())?,
	FailureResponse: string,
	FailureChoices: {any}?,
	FailureFlags: {string}?,
	FailureCommand: ((Player) -> ())?,
	OneTime: boolean?
}): any

	local SuccessNode: any = {
		Id = "skill_success_" .. Options.Skill:lower(),
		Text = Options.SuccessResponse
	}

	if Options.SuccessChoices then
		SuccessNode.Choices = Options.SuccessChoices
	end

	if Options.SuccessFlags then
		SuccessNode.SetFlags = Options.SuccessFlags
	end

	local FailureNode: any = {
		Id = "skill_failure_" .. Options.Skill:lower(),
		Text = Options.FailureResponse
	}

	if Options.FailureChoices then
		FailureNode.Choices = Options.FailureChoices
	end

	if Options.FailureFlags then
		FailureNode.SetFlags = Options.FailureFlags
	end

	return AdvancedDialogBuilder.CreateChoice(
		Options.ButtonText,
		SuccessNode,
		{
			SkillCheck = {
				Skill = Options.Skill,
				Difficulty = Options.Difficulty,
				OneTime = Options.OneTime ~= false
			},
			SuccessResponse = SuccessNode,
			FailureResponse = FailureNode,
			Command = function(Player: Player)
				local SkillValue = Player:GetAttribute("Skill_" .. Options.Skill) or 0
				local Roll = math.random(1, 20)
				local Success = (Roll + SkillValue) >= Options.Difficulty

				local CheckFlag = "SkillCheck_" .. Options.Skill .. "_" .. Options.ButtonText:gsub("%W", "")
				if Options.OneTime ~= false then
					DialogDataManager.SetSkillCheckCompleted(Player, CheckFlag)
				end

				if Success and Options.SuccessCommand then
					Options.SuccessCommand(Player)
				elseif not Success and Options.FailureCommand then
					Options.FailureCommand(Player)
				end
			end
		}
	)
end

function Advanced.CreateConditionalChoice(Options: {
	ButtonText: string,
	ResponseText: string,
	Conditions: {any},
	RequireAll: boolean?,
	SubChoices: {any}?,
	SetFlags: {string}?,
	Command: ((Player) -> ())?
}): any

	local Node = {
		Id = "conditional_" .. Options.ButtonText:gsub("%s", "_"):lower(),
		Text = Options.ResponseText,
		Choices = Options.SubChoices,
		SetFlags = Options.SetFlags
	}

	return AdvancedDialogBuilder.CreateChoice(
		Options.ButtonText,
		Node,
		{
			Conditions = Options.Conditions,
			RequireAll = Options.RequireAll,
			Command = Options.Command
		}
	)
end

function Advanced.CreateFlagGatedChoice(Options: {
	ButtonText: string,
	ResponseText: string,
	RequiredFlag: string,
	SubChoices: {any}?,
	SetFlags: {string}?,
	Command: ((Player) -> ())?
}): any

	return Advanced.CreateConditionalChoice({
		ButtonText = Options.ButtonText,
		ResponseText = Options.ResponseText,
		Conditions = {
			{Type = "DialogFlag", Value = Options.RequiredFlag}
		},
		SubChoices = Options.SubChoices,
		SetFlags = Options.SetFlags,
		Command = Options.Command
	})
end

function Advanced.CreateQuestGatedChoice(Options: {
	ButtonText: string,
	ResponseText: string,
	RequiredQuest: string,
	MustBeActive: boolean?,
	CanTurnIn: boolean?,
	SubChoices: {any}?,
	SetFlags: {string}?,
	Command: ((Player) -> ())?
}): any

	local ConditionType
	if Options.CanTurnIn then
		ConditionType = "CanTurnInQuest"
	elseif Options.MustBeActive then
		ConditionType = "HasQuest"
	else
		ConditionType = "CompletedQuest"
	end

	return Advanced.CreateConditionalChoice({
		ButtonText = Options.ButtonText,
		ResponseText = Options.ResponseText,
		Conditions = {
			{Type = ConditionType, Value = Options.RequiredQuest}
		},
		SubChoices = Options.SubChoices,
		SetFlags = Options.SetFlags,
		Command = Options.Command
	})
end

function Advanced.CreateReputationGatedChoice(Options: {
	ButtonText: string,
	ResponseText: string,
	Faction: string,
	MinRep: number,
	SubChoices: {any}?,
	SetFlags: {string}?,
	Command: ((Player) -> ())?
}): any

	return Advanced.CreateConditionalChoice({
		ButtonText = Options.ButtonText,
		ResponseText = Options.ResponseText,
		Conditions = {
			{Type = "HasReputation", Value = {Faction = Options.Faction, Min = Options.MinRep}}
		},
		SubChoices = Options.SubChoices,
		SetFlags = Options.SetFlags,
		Command = Options.Command
	})
end

function Advanced.CreateMultiSkillCheck(Options: {
	ButtonText: string,
	Checks: {{Skill: Skills, Difficulty: number}},
	RequireAll: boolean?,
	ResponseText: string,
	SubChoices: {any}?,
	SetFlags: {string}?,
	Command: ((Player) -> ())?
}): any

	local CheckText = "["
	for Index, Check in ipairs(Options.Checks) do
		CheckText = CheckText .. Check.Skill .. " " .. tostring(Check.Difficulty)
		if Index < #Options.Checks then
			CheckText = CheckText .. (Options.RequireAll and " + " or " / ")
		end
	end
	CheckText = CheckText .. "] " .. Options.ButtonText

	return AdvancedDialogBuilder.CreateChoice(
		CheckText,
		{
			Id = "multi_skill_check",
			Text = Options.ResponseText,
			Choices = Options.SubChoices,
			SetFlags = Options.SetFlags
		},
		{
			Command = Options.Command
		}
	)
end

function Advanced.CreateThoughtCabinetChoice(Options: {
	ButtonText: string,
	ThoughtText: string,
	ThoughtDuration: number?,
	RewardText: string?,
	SetFlags: {string}?,
	Command: ((Player) -> ())?
}): any

	local Duration = Options.ThoughtDuration or 60

	return {
		Text = Options.ButtonText,
		Response = {
			Id = "thought_" .. Options.ButtonText:gsub("%s", "_"):lower(),
			Text = Options.ThoughtText,
			SetFlags = Options.SetFlags
		},
		Command = function(Plr: Player)
			Plr:SetAttribute("ActiveThought", Options.ButtonText)
			Plr:SetAttribute("ThoughtStartTime", os.time())
			Plr:SetAttribute("ThoughtDuration", Duration)

			if Options.Command then
				Options.Command(Plr)
			end

			task.delay(Duration, function()
				if Plr:GetAttribute("ActiveThought") == Options.ButtonText then
					Plr:SetAttribute("ActiveThought", nil)
					if Options.RewardText then
						print("[Thought Complete]", Options.RewardText)
					end
				end
			end)
		end
	}
end

function Advanced.CreateDialogWithMood(Options: {
	ButtonText: string,
	Mood: string,
	ResponseText: string,
	SubChoices: {any}?,
	SetFlags: {string}?,
	Command: ((Player) -> ())?
}): any

	local MoodPrefix = "[" .. Options.Mood:upper() .. "] "

	return {
		Text = MoodPrefix .. Options.ButtonText,
		Response = {
			Id = "mood_" .. Options.Mood:lower(),
			Text = Options.ResponseText,
			Choices = Options.SubChoices,
			SetFlags = Options.SetFlags
		},
		Command = Options.Command
	}
end

return Advanced