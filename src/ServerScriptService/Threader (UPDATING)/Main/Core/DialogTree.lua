--!strict

local DialogTree = {}

export type SkillCheck = {
	Skill: string,
	Difficulty: number,
	SuccessNode: DialogNode?,
	FailureNode: DialogNode?
}

export type Condition = {
	Type: string,
	Value: any
}

export type Quest = {
	QuestId: string,
	OfferText: string,
	Description: string
}

export type QuestTurnIn = {
	QuestId: string,
	SuccessText: string,
	FailureText: string?
}

export type DialogChoice = {
	Text: string,
	ResponseNode: DialogNode?,
	SkillCheck: SkillCheck?,
	Conditions: {Condition}?,
	Quest: Quest?,
	QuestTurnIn: QuestTurnIn?,
	ReturnToNodeId: string?,
	FlagsSet: {string}?,
	FlagsRemoved: {string}?,
	Command: string?
}

export type DialogNode = {
	Id: string,
	Text: string,
	Choices: {DialogChoice}?,
	NextResponseNode: DialogNode?,
	ReturnToNodeId: string?,
	FlagsSet: {string}?,
	FlagsRemoved: {string}?,
	Command: string?
}

function DialogTree.CreateNode(Id: string, Text: string): DialogNode
	return {
		Id = Id,
		Text = Text,
		Choices = nil,
		NextResponseNode = nil,
		ReturnToNodeId = nil,
		FlagsSet = nil,
		FlagsRemoved = nil,
		Command = nil
	}
end

function DialogTree.CreateChoice(Text: string): DialogChoice
	return {
		Text = Text,
		ResponseNode = nil,
		SkillCheck = nil,
		Conditions = nil,
		Quest = nil,
		QuestTurnIn = nil,
		ReturnToNodeId = nil,
		FlagsSet = nil,
		FlagsRemoved = nil,
		Command = nil
	}
end

function DialogTree.CreateSkillCheck(Skill: string, Difficulty: number): SkillCheck
	return {
		Skill = Skill,
		Difficulty = Difficulty,
		SuccessNode = nil,
		FailureNode = nil
	}
end

function DialogTree.CreateCondition(Type: string, Value: any): Condition
	return {
		Type = Type,
		Value = Value
	}
end

function DialogTree.CreateQuest(QuestId: string, OfferText: string, Description: string): Quest
	return {
		QuestId = QuestId,
		OfferText = OfferText,
		Description = Description
	}
end

function DialogTree.CreateQuestTurnIn(QuestId: string, SuccessText: string, FailureText: string?): QuestTurnIn
	return {
		QuestId = QuestId,
		SuccessText = SuccessText,
		FailureText = FailureText
	}
end

function DialogTree.AddChoice(Node: DialogNode, Choice: DialogChoice)
	if not Node.Choices then
		Node.Choices = {}
	end
	table.insert(Node.Choices, Choice)
end

function DialogTree.RemoveChoice(Node: DialogNode, ChoiceIndex: number): boolean
	if not Node.Choices or ChoiceIndex < 1 or ChoiceIndex > #Node.Choices then
		return false
	end
	table.remove(Node.Choices, ChoiceIndex)
	return true
end

function DialogTree.FindNodeById(Root: DialogNode, TargetId: string): DialogNode?
	local Visited: {[DialogNode]: boolean} = {}

	local function Search(Node: DialogNode): DialogNode?
		if Visited[Node] then
			return nil
		end
		Visited[Node] = true

		if Node.Id == TargetId then
			return Node
		end

		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					local Found = Search(Choice.ResponseNode)
					if Found then return Found end
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						local Found = Search(Choice.SkillCheck.SuccessNode)
						if Found then return Found end
					end
					if Choice.SkillCheck.FailureNode then
						local Found = Search(Choice.SkillCheck.FailureNode)
						if Found then return Found end
					end
				end
			end
		end

		if Node.NextResponseNode then
			return Search(Node.NextResponseNode)
		end

		return nil
	end

	return Search(Root)
end

function DialogTree.FindChoiceByText(Node: DialogNode, Text: string): DialogChoice?
	if not Node.Choices then
		return nil
	end

	for _, Choice in ipairs(Node.Choices) do
		if Choice.Text == Text then
			return Choice
		end
	end

	return nil
end

function DialogTree.GetAllNodes(Root: DialogNode): {DialogNode}
	local Nodes: {DialogNode} = {}
	local Visited: {[DialogNode]: boolean} = {}

	local function Traverse(Node: DialogNode)
		if Visited[Node] then
			return
		end
		Visited[Node] = true

		table.insert(Nodes, Node)

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

		if Node.NextResponseNode then
			Traverse(Node.NextResponseNode)
		end
	end

	Traverse(Root)
	return Nodes
end

function DialogTree.GetNodeDepth(Root: DialogNode, TargetNode: DialogNode): number?
	local function FindDepth(Node: DialogNode, Depth: number): number?
		if Node == TargetNode then
			return Depth
		end

		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					local Found = FindDepth(Choice.ResponseNode, Depth + 1)
					if Found then return Found end
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						local Found = FindDepth(Choice.SkillCheck.SuccessNode, Depth + 1)
						if Found then return Found end
					end
					if Choice.SkillCheck.FailureNode then
						local Found = FindDepth(Choice.SkillCheck.FailureNode, Depth + 1)
						if Found then return Found end
					end
				end
			end
		end

		if Node.NextResponseNode then
			return FindDepth(Node.NextResponseNode, Depth + 1)
		end

		return nil
	end

	return FindDepth(Root, 0)
end

function DialogTree.CountNodes(Root: DialogNode): number
	return #DialogTree.GetAllNodes(Root)
end

function DialogTree.HasCircularReference(Root: DialogNode): boolean
	local Visiting: {[DialogNode]: boolean} = {}
	local Visited: {[DialogNode]: boolean} = {}

	local function CheckCycle(Node: DialogNode): boolean
		if Visiting[Node] then
			return true
		end

		if Visited[Node] then
			return false
		end

		Visiting[Node] = true

		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode and CheckCycle(Choice.ResponseNode) then
					return true
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode and CheckCycle(Choice.SkillCheck.SuccessNode) then
						return true
					end
					if Choice.SkillCheck.FailureNode and CheckCycle(Choice.SkillCheck.FailureNode) then
						return true
					end
				end
			end
		end

		if Node.NextResponseNode and CheckCycle(Node.NextResponseNode) then
			return true
		end

		Visiting[Node] = nil
		Visited[Node] = true
		return false
	end

	return CheckCycle(Root)
end

function DialogTree.ValidateNodeIds(Root: DialogNode): {string}
	local Errors: {string} = {}
	local SeenIds: {[string]: boolean} = {}

	local function CheckNode(Node: DialogNode)
		if not Node.Id or Node.Id == "" then
			table.insert(Errors, "Node has empty or missing ID")
		elseif SeenIds[Node.Id] then
			table.insert(Errors, "Duplicate node ID: " .. Node.Id)
		else
			SeenIds[Node.Id] = true
		end

		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					CheckNode(Choice.ResponseNode)
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						CheckNode(Choice.SkillCheck.SuccessNode)
					end
					if Choice.SkillCheck.FailureNode then
						CheckNode(Choice.SkillCheck.FailureNode)
					end
				end
			end
		end

		if Node.NextResponseNode then
			CheckNode(Node.NextResponseNode)
		end
	end

	CheckNode(Root)
	return Errors
end

function DialogTree.SetNodeFlags(Node: DialogNode, FlagsToSet: {string}?, FlagsToRemove: {string}?)
	Node.FlagsSet = FlagsToSet
	Node.FlagsRemoved = FlagsToRemove
end

function DialogTree.SetChoiceFlags(Choice: DialogChoice, FlagsToSet: {string}?, FlagsToRemove: {string}?)
	Choice.FlagsSet = FlagsToSet
	Choice.FlagsRemoved = FlagsToRemove
end

function DialogTree.AddConditionToChoice(Choice: DialogChoice, Condition: Condition)
	if not Choice.Conditions then
		Choice.Conditions = {}
	end
	table.insert(Choice.Conditions, Condition)
end

function DialogTree.RemoveConditionFromChoice(Choice: DialogChoice, Index: number): boolean
	if not Choice.Conditions or Index < 1 or Index > #Choice.Conditions then
		return false
	end
	table.remove(Choice.Conditions, Index)
	return true
end

function DialogTree.CloneNode(Node: DialogNode): DialogNode
	local TableUtils = require(script.Parent.Parent.Utils.TableUtils)
	return TableUtils.DeepCopy(Node)
end

function DialogTree.CloneChoice(Choice: DialogChoice): DialogChoice
	local TableUtils = require(script.Parent.Parent.Utils.TableUtils)
	return TableUtils.DeepCopy(Choice)
end

function DialogTree.GetParentNode(Root: DialogNode, TargetNode: DialogNode): DialogNode?
	local function Search(Node: DialogNode): DialogNode?
		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode == TargetNode then
					return Node
				end

				if Choice.ResponseNode then
					local Found = Search(Choice.ResponseNode)
					if Found then return Found end
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode == TargetNode or Choice.SkillCheck.FailureNode == TargetNode then
						return Node
					end

					if Choice.SkillCheck.SuccessNode then
						local Found = Search(Choice.SkillCheck.SuccessNode)
						if Found then return Found end
					end
					if Choice.SkillCheck.FailureNode then
						local Found = Search(Choice.SkillCheck.FailureNode)
						if Found then return Found end
					end
				end
			end
		end

		if Node.NextResponseNode == TargetNode then
			return Node
		end

		if Node.NextResponseNode then
			return Search(Node.NextResponseNode)
		end

		return nil
	end

	return Search(Root)
end

function DialogTree.IsLeafNode(Node: DialogNode): boolean
	return (not Node.Choices or #Node.Choices == 0) and not Node.NextResponseNode
end

function DialogTree.GetLeafNodes(Root: DialogNode): {DialogNode}
	local Leaves: {DialogNode} = {}
	local AllNodes = DialogTree.GetAllNodes(Root)

	for _, Node in ipairs(AllNodes) do
		if DialogTree.IsLeafNode(Node) then
			table.insert(Leaves, Node)
		end
	end

	return Leaves
end

function DialogTree.GetMaxDepth(Root: DialogNode): number
	local MaxDepth = 0

	local function Traverse(Node: DialogNode, Depth: number)
		MaxDepth = math.max(MaxDepth, Depth)

		if Node.Choices then
			for _, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					Traverse(Choice.ResponseNode, Depth + 1)
				end

				if Choice.SkillCheck then
					if Choice.SkillCheck.SuccessNode then
						Traverse(Choice.SkillCheck.SuccessNode, Depth + 1)
					end
					if Choice.SkillCheck.FailureNode then
						Traverse(Choice.SkillCheck.FailureNode, Depth + 1)
					end
				end
			end
		end

		if Node.NextResponseNode then
			Traverse(Node.NextResponseNode, Depth + 1)
		end
	end

	Traverse(Root, 0)
	return MaxDepth
end

function DialogTree.GetBranchingFactor(Node: DialogNode): number
	if not Node.Choices then
		return 0
	end
	return #Node.Choices
end

function DialogTree.GetAverageBranchingFactor(Root: DialogNode): number
	local AllNodes = DialogTree.GetAllNodes(Root)
	local TotalBranching = 0
	local NodesWithChoices = 0

	for _, Node in ipairs(AllNodes) do
		if Node.Choices and #Node.Choices > 0 then
			TotalBranching = TotalBranching + #Node.Choices
			NodesWithChoices = NodesWithChoices + 1
		end
	end

	if NodesWithChoices == 0 then
		return 0
	end

	return TotalBranching / NodesWithChoices
end

return DialogTree