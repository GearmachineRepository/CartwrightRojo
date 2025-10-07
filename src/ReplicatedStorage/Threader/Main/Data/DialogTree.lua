--!strict
local DialogTree = {}

export type DialogNode = {
	Id: string,
	Text: string,
	Choices: {DialogChoice}?,
	Greetings: {ConditionalGreeting}?,
	LoopBehavior: string?
}

export type ConditionalGreeting = {
	ConditionType: string,
	ConditionValue: string,
	GreetingText: string
}

export type ResponseTypes = "DefaultResponse" | "ReturnToStart" | "ReturnToNode" | "EndDialog"

export type DialogChoice = {
	Id: string,
	ButtonText: string,
	ResponseType: ResponseTypes?,
	ResponseNode: DialogNode?,
	ReturnToNodeId: string?,
	SkillCheck: SkillCheckData?,
	QuestTurnIn: QuestTurnInData?,
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

export type QuestTurnInData = {
	QuestId: string,
	ResponseText: string
}

local LOOP_BEHAVIORS = {
	END_DIALOG = "EndDialog",
	LOOP_TO_START = "LoopToStart",
	LOOP_TO_NODE = "LoopToNode"
}

local RESPONSE_TYPES = {
	DEFAULT_RESPONSE = "DefaultResponse",
	RETURN_TO_START = "ReturnToStart",
	RETURN_TO_NODE = "ReturnToNode",
	END_DIALOG = "EndDialog"
}

DialogTree.LOOP_BEHAVIORS = LOOP_BEHAVIORS
DialogTree.RESPONSE_TYPES = RESPONSE_TYPES

local NodeIdCounter = 0

local function GenerateUniqueId(Prefix: string): string
	NodeIdCounter = NodeIdCounter + 1
	return Prefix .. "_" .. tostring(NodeIdCounter)
end

function DialogTree.CreateNode(Id: string, Text: string): DialogNode
	return {
		Id = Id,
		Text = Text,
		Choices = {},
		Greetings = {},
		LoopBehavior = LOOP_BEHAVIORS.END_DIALOG
	}
end

function DialogTree.CreateChoice(ButtonText: string): DialogChoice
	return {
		Id = GenerateUniqueId("choice"),
		ButtonText = ButtonText,
		ResponseType = RESPONSE_TYPES.DEFAULT_RESPONSE,
		ResponseNode = DialogTree.CreateNode(GenerateUniqueId("response"), "Response text..."),
	}
end

function DialogTree.CreateSkillCheck(ButtonText: string, Skill: string, Difficulty: number): DialogChoice
	return {
		Id = GenerateUniqueId("choice"),
		ButtonText = ButtonText,
		ResponseType = RESPONSE_TYPES.DEFAULT_RESPONSE,
		SkillCheck = {
			Skill = Skill,
			Difficulty = Difficulty,
			SuccessNode = DialogTree.CreateNode(GenerateUniqueId("success"), "Success response..."),
			FailureNode = DialogTree.CreateNode(GenerateUniqueId("failure"), "Failure response...")
		}
	}
end

function DialogTree.CreateQuestTurnIn(ButtonText: string, QuestId: string): DialogChoice
	return {
		Id = GenerateUniqueId("choice"),
		ButtonText = ButtonText,
		ResponseType = RESPONSE_TYPES.DEFAULT_RESPONSE,
		QuestTurnIn = {
			QuestId = QuestId,
			ResponseText = "Thank you! Here's your reward."
		}
	}
end

function DialogTree.SetResponseType(Choice: DialogChoice, ResponseType: string)
	if ResponseType == RESPONSE_TYPES.DEFAULT_RESPONSE then
		Choice.ResponseType = ResponseType
		if not Choice.ResponseNode then
			Choice.ResponseNode = DialogTree.CreateNode(GenerateUniqueId("response"), "Response text...")
		end
		Choice.ReturnToNodeId = nil
	elseif ResponseType == RESPONSE_TYPES.RETURN_TO_START then
		Choice.ResponseType = ResponseType
		Choice.ResponseNode = nil
		Choice.ReturnToNodeId = nil
	elseif ResponseType == RESPONSE_TYPES.RETURN_TO_NODE then
		Choice.ResponseType = ResponseType
		Choice.ResponseNode = nil
	end
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

function DialogTree.AddGreeting(Node: DialogNode, ConditionType: string, ConditionValue: string, GreetingText: string)
	if not Node.Greetings then
		Node.Greetings = {}
	end
	table.insert(Node.Greetings, {
		ConditionType = ConditionType,
		ConditionValue = ConditionValue,
		GreetingText = GreetingText
	})
end

function DialogTree.RemoveGreeting(Node: DialogNode, Index: number)
	if Node.Greetings then
		table.remove(Node.Greetings, Index)
	end
end

function DialogTree.ConvertToSkillCheck(Choice: DialogChoice, Skill: string, Difficulty: number)
	Choice.ResponseNode = nil
	Choice.QuestTurnIn = nil
	Choice.SkillCheck = {
		Skill = Skill,
		Difficulty = Difficulty,
		SuccessNode = DialogTree.CreateNode(GenerateUniqueId("success"), "Success response..."),
		FailureNode = DialogTree.CreateNode(GenerateUniqueId("failure"), "Failure response...")
	}
end

function DialogTree.ConvertToQuestTurnIn(Choice: DialogChoice, QuestId: string)
	Choice.ResponseNode = nil
	Choice.SkillCheck = nil
	Choice.QuestTurnIn = {
		QuestId = QuestId,
		ResponseText = "Thank you! Here's your reward."
	}
end

function DialogTree.ConvertToSimpleChoice(Choice: DialogChoice)
	Choice.SkillCheck = nil
	Choice.QuestTurnIn = nil
	if not Choice.ResponseNode then
		Choice.ResponseNode = DialogTree.CreateNode(GenerateUniqueId("response"), "Response text...")
	end
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

function DialogTree.GetAllNodeIds(Root: DialogNode): {string}
	local NodeIds = {}
	local Visited = {}

	local function Traverse(Node: DialogNode)
		if Visited[Node] then return end
		Visited[Node] = true

		table.insert(NodeIds, Node.Id)

		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					Traverse(Choice.ResponseNode)
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						Traverse(Choice.SkillCheck.SuccessNode)
					end
					if Choice.SkillCheck.FailureNode then
						Traverse(Choice.SkillCheck.FailureNode)
					end
				end
			end
		end
	end

	Traverse(Root)
	return NodeIds
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

function DialogTree.SetLoopBehavior(Node: DialogNode, Behavior: string)
	if Behavior == LOOP_BEHAVIORS.END_DIALOG or
	   Behavior == LOOP_BEHAVIORS.LOOP_TO_START or
	   Behavior == LOOP_BEHAVIORS.LOOP_TO_NODE then
		Node.LoopBehavior = Behavior
	end
end

function DialogTree.SetReturnToNode(Choice: DialogChoice, NodeId: string?)
	Choice.ReturnToNodeId = NodeId
end

return DialogTree