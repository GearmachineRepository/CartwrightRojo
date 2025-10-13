--!strict
local TableUtils = require(script.Parent.Parent.Utils.TableUtils)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local ClipboardManager = {}

local ClipboardData: any? = nil
local ClipboardType: string? = nil

local function GenerateNewIds(Node: DialogNode, IdMap: {[string]: string})
	local OldId = Node.Id
	local NewId = OldId .. "_copy_" .. tostring(tick()):sub(-6)
	IdMap[OldId] = NewId
	Node.Id = NewId

	if Node.Choices then
		for _, Choice in ipairs(Node.Choices) do
			if Choice.ReturnToNodeId and IdMap[Choice.ReturnToNodeId] then
				Choice.ReturnToNodeId = IdMap[Choice.ReturnToNodeId]
			end

			if Choice.ResponseNode then
				GenerateNewIds(Choice.ResponseNode, IdMap)
			end

			if Choice.SkillCheck then
				if Choice.SkillCheck.SuccessNode then
					GenerateNewIds(Choice.SkillCheck.SuccessNode, IdMap)
				end
				if Choice.SkillCheck.FailureNode then
					GenerateNewIds(Choice.SkillCheck.FailureNode, IdMap)
				end
			end
		end
	end

	if Node.NextResponseNode then
		GenerateNewIds(Node.NextResponseNode, IdMap)
	end

	if Node.ReturnToNodeId and IdMap[Node.ReturnToNodeId] then
		Node.ReturnToNodeId = IdMap[Node.ReturnToNodeId]
	end
end

function ClipboardManager.CopyNode(Node: DialogNode)
	ClipboardData = TableUtils.DeepCopy(Node)
	ClipboardType = "Node"
end

function ClipboardManager.CopyChoice(Choice: DialogChoice)
	ClipboardData = TableUtils.DeepCopy(Choice)
	ClipboardType = "Choice"
end

function ClipboardManager.Paste(): any?
	if not ClipboardData then
		return nil
	end

	local Copy = TableUtils.DeepCopy(ClipboardData)
	local IdMap: {[string]: string} = {}

	if ClipboardType == "Node" then
		GenerateNewIds(Copy, IdMap)
	end

	return Copy
end

function ClipboardManager.Cut(Node: DialogNode)
	ClipboardManager.CopyNode(Node)
	return Node
end

function ClipboardManager.CanPaste(): boolean
	return ClipboardData ~= nil
end

function ClipboardManager.GetClipboardType(): string?
	return ClipboardType
end

function ClipboardManager.Clear()
	ClipboardData = nil
	ClipboardType = nil
end

return ClipboardManager