--!strict
local DialogTree = {}

export type DialogNode = {
	Id: string,
	Text: string,
	Choices: {DialogChoice}?
}

export type DialogChoice = {
	ButtonText: string,
	ResponseNode: DialogNode?,
	SkillCheck: SkillCheckData?,
	Conditions: {ConditionData}?,
	Command: string?,
	SetFlags: {string}?
}

export type ConditionData = {
	Type: string,
	Value: any,
	Negate: boolean?
}

export type SkillCheckData = {
	Skill: string,
	Difficulty: number,
	SuccessNode: DialogNode?,
	FailureNode: DialogNode?
}

function DialogTree.CreateNode(Id: string, Text: string): DialogNode
	return {
		Id = Id,
		Text = Text,
		Choices = {}
	}
end

function DialogTree.CreateChoice(ButtonText: string): DialogChoice
	return {
		ButtonText = ButtonText,
		ResponseNode = DialogTree.CreateNode("response", "Response text..."),
	}
end

function DialogTree.CreateSkillCheck(ButtonText: string, Skill: string, Difficulty: number): DialogChoice
	return {
		ButtonText = ButtonText,
		SkillCheck = {
			Skill = Skill,
			Difficulty = Difficulty,
			SuccessNode = DialogTree.CreateNode("success", "Success response..."),
			FailureNode = DialogTree.CreateNode("failure", "Failure response...")
		}
	}
end

function DialogTree.AddChoice(Node: DialogNode, Choice: DialogChoice)
	if not Node.Choices then
		Node.Choices = {}
	end
	table.insert(Node.Choices, Choice)
end

function DialogTree.RemoveChoice(Node: DialogNode, Index: number)
	if Node.Choices then
		table.remove(Node.Choices, Index)
	end
end

function DialogTree.ConvertToSkillCheck(Choice: DialogChoice, Skill: string, Difficulty: number)
	Choice.ResponseNode = nil
	Choice.SkillCheck = {
		Skill = Skill,
		Difficulty = Difficulty,
		SuccessNode = DialogTree.CreateNode("success", "Success response..."),
		FailureNode = DialogTree.CreateNode("failure", "Failure response...")
	}
end

function DialogTree.ConvertToSimpleChoice(Choice: DialogChoice)
	Choice.SkillCheck = nil
	Choice.ResponseNode = DialogTree.CreateNode("response", "Response text...")
end

function DialogTree.FindNodeById(Root: DialogNode, Id: string): DialogNode?
	if Root.Id == Id then
		return Root
	end

	if Root.Choices then
		for _, Choice in ipairs(Root.Choices) do
			if Choice.ResponseNode then
				local Found = DialogTree.FindNodeById(Choice.ResponseNode, Id)
				if Found then return Found end
			end

			if Choice.SkillCheck then
				if Choice.SkillCheck.SuccessNode then
					local Found = DialogTree.FindNodeById(Choice.SkillCheck.SuccessNode, Id)
					if Found then return Found end
				end
				if Choice.SkillCheck.FailureNode then
					local Found = DialogTree.FindNodeById(Choice.SkillCheck.FailureNode, Id)
					if Found then return Found end
				end
			end
		end
	end

	return nil
end

function DialogTree.AddCondition(Choice: DialogChoice, ConditionType: string, Value: any)
	if not Choice.Conditions then
		Choice.Conditions = {}
	end
	table.insert(Choice.Conditions, {
		Type = ConditionType,
		Value = Value,
		Negate = false
	})
end

function DialogTree.RemoveCondition(Choice: DialogChoice, Index: number)
	if Choice.Conditions then
		table.remove(Choice.Conditions, Index)
	end
end

function DialogTree.AddFlag(Choice: DialogChoice, FlagName: string)
	if not Choice.SetFlags then
		Choice.SetFlags = {}
	end
	table.insert(Choice.SetFlags, FlagName)
end

function DialogTree.RemoveFlag(Choice: DialogChoice, Index: number)
	if Choice.SetFlags then
		table.remove(Choice.SetFlags, Index)
	end
end

return DialogTree