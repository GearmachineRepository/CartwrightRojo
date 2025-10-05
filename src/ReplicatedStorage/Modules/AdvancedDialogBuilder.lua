--!strict
local AdvancedDialogBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogConditions = require(Modules:WaitForChild("DialogConditions"))

export type Condition = DialogConditions.Condition

export type ConditionalChoice = {
	Text: string,
	Response: DialogNode,
	SuccessResponse: DialogNode?,
	FailureResponse: DialogNode?,
	Command: ((Player) -> ())?,
	Conditions: {Condition}?,
	RequireAll: boolean?,
	SkillCheck: {Skill: string, Difficulty: number, SuccessText: string?, FailureText: string?, OneTime: boolean?}?
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

function AdvancedDialogBuilder.FilterChoices(Player: Player, Choices: {ConditionalChoice}): {{Text: string, Response: any, Command: any, SkillCheckSuccess: boolean?}}
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
			-- Check if already used (one-time check)
			local CheckFlag = "SkillCheck_" .. Choice.SkillCheck.Skill .. "_" .. Choice.Text:gsub("%W", "")
			if Choice.SkillCheck.OneTime and Player:GetAttribute(CheckFlag) then
				IsValid = false
			else
				local SkillValue = Player:GetAttribute("Skill_" .. Choice.SkillCheck.Skill) or 0
				local Roll = math.random(1, 20)
				local Success = (Roll + SkillValue) >= Choice.SkillCheck.Difficulty

				if Choice.SkillCheck.OneTime then
					Player:SetAttribute(CheckFlag, true)
				end

				local BaseChance = (SkillValue + 10.5 - Choice.SkillCheck.Difficulty) / 20 * 100
				local Chance = math.clamp(math.floor(BaseChance), 5, 95)

				local DisplayText = Choice.Text

				local ResponseToUse = Choice.Response
				if Success and Choice.SuccessResponse then
					ResponseToUse = Choice.SuccessResponse
				elseif not Success and Choice.FailureResponse then
					ResponseToUse = Choice.FailureResponse
				end

				if not ResponseToUse or not ResponseToUse.Text then
					ResponseToUse = Choice.Response
				end

				table.insert(ValidChoices, {
					Text = string.format("[%s %d] %s (%d%%)",
						Choice.SkillCheck.Skill,
						Choice.SkillCheck.Difficulty,
						DisplayText,
						Chance
					),
					Response = ResponseToUse,
					Command = Choice.Command,
					SkillCheckSuccess = Success
				})
			end
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