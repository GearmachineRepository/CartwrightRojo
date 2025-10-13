--!strict
local DialogTree = require(script.Parent.DialogTree)
local TableUtils = require(script.Parent.Parent.Utils.TableUtils)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local TreeOperations = {}

function TreeOperations.FindNode(Root: DialogNode, Predicate: (DialogNode) -> boolean): DialogNode?
	if Predicate(Root) then
		return Root
	end

	if Root.Choices then
		for _, Choice in ipairs(Root.Choices) do
			if Choice.ResponseNode then
				local Found = TreeOperations.FindNode(Choice.ResponseNode, Predicate)
				if Found then return Found end
			end

			if Choice.SkillCheck then
				if Choice.SkillCheck.SuccessNode then
					local Found = TreeOperations.FindNode(Choice.SkillCheck.SuccessNode, Predicate)
					if Found then return Found end
				end
				if Choice.SkillCheck.FailureNode then
					local Found = TreeOperations.FindNode(Choice.SkillCheck.FailureNode, Predicate)
					if Found then return Found end
				end
			end
		end
	end

	if Root.NextResponseNode then
		return TreeOperations.FindNode(Root.NextResponseNode, Predicate)
	end

	return nil
end

function TreeOperations.GetAllNodes(Root: DialogNode): {DialogNode}
	local Nodes: {DialogNode} = {}
	local Visited: {[DialogNode]: boolean} = {}

	local function Traverse(Node: DialogNode)
		if Visited[Node] then return end
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

function TreeOperations.GetDepth(Node: DialogNode, Root: DialogNode): number
	local function FindDepth(CurrentNode: DialogNode, Depth: number): number?
		if CurrentNode == Node then
			return Depth
		end

		if CurrentNode.Choices then
			for _, Choice in ipairs(CurrentNode.Choices) do
				if Choice.ResponseNode then
					local Found = FindDepth(Choice.ResponseNode, Depth + 1)
					if Found then return Found end
				end
			end
		end

		if CurrentNode.NextResponseNode then
			return FindDepth(CurrentNode.NextResponseNode, Depth + 1)
		end

		return nil
	end

	return FindDepth(Root, 0) or 0
end

function TreeOperations.CloneSubtree(Node: DialogNode): DialogNode
	return TableUtils.DeepCopy(Node)
end

function TreeOperations.CountNodes(Root: DialogNode): number
	return #TreeOperations.GetAllNodes(Root)
end

function TreeOperations.GetNodePath(Root: DialogNode, TargetNode: DialogNode): {string}
	local Path: {string} = {}

	local function FindPath(Node: DialogNode, CurrentPath: {string}): boolean
		if Node == TargetNode then
			for _, Segment in ipairs(CurrentPath) do
				table.insert(Path, Segment)
			end
			return true
		end

		if Node.Choices then
			for Index, Choice in ipairs(Node.Choices) do
				if Choice.ResponseNode then
					table.insert(CurrentPath, "Choice[" .. Index .. "]")
					if FindPath(Choice.ResponseNode, CurrentPath) then
						return true
					end
					table.remove(CurrentPath)
				end
			end
		end

		if Node.NextResponseNode then
			table.insert(CurrentPath, "NextResponse")
			if FindPath(Node.NextResponseNode, CurrentPath) then
				return true
			end
			table.remove(CurrentPath)
		end

		return false
	end

	FindPath(Root, {})
	return Path
end

return TreeOperations