--!strict
local AdvancedDialogBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogConditions = require(Modules:WaitForChild("DialogConditions"))

export type Condition = DialogConditions.Condition

export type ConditionalChoice = {
	Text: string,
	Response: DialogNode,
	Command: ((Player) -> ())?,
	Conditions: {Condition}?,
	RequireAll: boolean?,
	SkillCheck: {Skill: string, Difficulty: number, SuccessText: string?, FailureText: string?}?
}

export type DialogNode = {
	Id: string,
	Text: string,
	Choices: {ConditionalChoice}?,
	OpenGui: string?,
	GiveQuest: string?,
	TurnInQuest: string?,
	SetFlags: {string}?,
	OnEnter: ((Player) -> ())?
}

function AdvancedDialogBuilder.FilterChoices(Player: Player, Choices: {ConditionalChoice}): {{Text: string, Response: any, Command: any}}
	local ValidChoices = {}

	for _, Choice in ipairs(Choices) do
		local IsValid = true

		if Choice.Conditions then
			if Choice.RequireAll == false then
				IsValid = DialogConditions.CheckAny(Player, Choice.Conditions)
			else
				IsValid = DialogConditions.CheckAll(Player, Choice.Conditions)
			end
		end

		if IsValid and Choice.SkillCheck then
			local SkillValue = Player:GetAttribute("Skill_" .. Choice.SkillCheck.Skill) or 0
			local Success = math.random(1, 20) + SkillValue >= Choice.SkillCheck.Difficulty

			local DisplayText = Choice.Text
			if Choice.SkillCheck.SuccessText and Success then
				DisplayText = Choice.SkillCheck.SuccessText
			elseif Choice.SkillCheck.FailureText and not Success then
				DisplayText = Choice.SkillCheck.FailureText
			end

			table.insert(ValidChoices, {
				Text = string.format("[%s %d] %s",
					Choice.SkillCheck.Skill,
					Choice.SkillCheck.Difficulty,
					DisplayText
				),
				Response = Choice.Response,
				Command = Choice.Command
			})
		elseif IsValid then
			table.insert(ValidChoices, {
				Text = Choice.Text,
				Response = Choice.Response,
				Command = Choice.Command
			})
		end
	end

	return ValidChoices
end

function AdvancedDialogBuilder.ProcessNode(Player: Player, Node: DialogNode): DialogNode
	if Node.SetFlags then
		for _, Flag in ipairs(Node.SetFlags) do
			DialogConditions.SetFlag(Player, Flag, true)
		end
	end

	if Node.OnEnter then
		pcall(Node.OnEnter, Player)
	end

	if Node.Choices then
		local FilteredChoices = AdvancedDialogBuilder.FilterChoices(Player, Node.Choices)
		return {
			Id = Node.Id,
			Text = Node.Text,
			Choices = FilteredChoices,
			OpenGui = Node.OpenGui,
			GiveQuest = Node.GiveQuest,
			TurnInQuest = Node.TurnInQuest
		}
	end

	return Node
end

function AdvancedDialogBuilder.CreateChoice(Text: string, ResponseNode: DialogNode, Options: {
	Conditions: {Condition}?,
	RequireAll: boolean?,
	Command: ((Player) -> ())?,
	SkillCheck: {Skill: string, Difficulty: number}?
}?): ConditionalChoice
	return {
		Text = Text,
		Response = ResponseNode,
		Conditions = Options and Options.Conditions,
		RequireAll = Options and Options.RequireAll,
		Command = Options and Options.Command,
		SkillCheck = Options and Options.SkillCheck
	}
end

return AdvancedDialogBuilder