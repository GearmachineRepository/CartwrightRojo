--!strict
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local CodeLibrary = script.Parent.Generators
local GreetingGen = require(CodeLibrary.GreetingGenerator)
local SimpleChoiceGen = require(CodeLibrary.SimpleChoiceGenerator)
local NestedChoiceGen = require(CodeLibrary.NestedChoiceGenerator)
local SkillCheckGen = require(CodeLibrary.SkillCheckGenerator)
local ConditionalGen = require(CodeLibrary.ConditionalGenerator)
local QuestGen = require(CodeLibrary.QuestGenerator)
local Helpers = require(script.Parent.Helpers)

local CodeGenerator = {}

local function GenerateNodeResponseType(Node: DialogNode, Depth: number): string
	if not Node.ResponseType or Node.ResponseType == DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
		return ""
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = ""

	if Node.ResponseType == DialogTree.RESPONSE_TYPES.CONTINUE_TO_RESPONSE and Node.NextResponseNode then
		Code = Code .. Indent .. "ResponseType = \"continue_to_response\",\n"
		Code = Code .. Indent .. "NextResponseNode = " .. CodeGenerator.GenerateNodeRecursive(Node.NextResponseNode, Depth) .. ",\n"
	elseif Node.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
		Code = Code .. Indent .. "ResponseType = \"return_to_start\",\n"
	elseif Node.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE and Node.ReturnToNodeId then
		Code = Code .. Indent .. "ResponseType = \"return_to_node\",\n"
		Code = Code .. Indent .. "ReturnToNodeId = \"" .. Node.ReturnToNodeId .. "\",\n"
	elseif Node.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
		Code = Code .. Indent .. "ResponseType = \"end_dialog\",\n"
	end

	return Code
end

function CodeGenerator.GenerateNodeRecursive(Node: DialogNode, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = "{\n"

	Code = Code .. Indent .. "\tId = \"" .. Node.Id .. "\",\n"
	Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Node.Text) .. "\",\n"

	Code = Code .. GenerateNodeResponseType(Node, Depth + 1)

	if Node.Choices and #Node.Choices > 0 then
		Code = Code .. Indent .. "\tChoices = {\n"
		for _, Choice in ipairs(Node.Choices) do
			Code = Code .. CodeGenerator.GenerateChoiceCode(Choice, Depth + 2)
		end
		Code = Code .. Indent .. "\t}\n"
	end

	Code = Code .. Indent .. "}"
	return Code
end

function CodeGenerator.Generate(Tree: DialogNode): string
	local Code = [[--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("AdvancedDialogBuilder"))
local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))
local DialogConditions = require(Modules:WaitForChild("DialogConditions"))
local QuestManager = require(Modules:WaitForChild("QuestManager"))

return function(Player: Player)
]]

	Code = Code .. GreetingGen.Generate(Tree)
	Code = Code .. "\tlocal Choices = {}\n\n"

	if Tree.Choices then
		for _, Choice in ipairs(Tree.Choices) do
			Code = Code .. CodeGenerator.GenerateChoiceCode(Choice, 1)
		end
	end

	Code = Code .. [[
	local DialogTree = DialogHelpers.CreateDialogStart(Greeting, Choices)

	return DialogBuilder.ProcessNode(Player, DialogTree)
end
]]

	return Code
end

function CodeGenerator.GenerateChoiceCode(Choice: DialogChoice, Depth: number): string
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
		return SimpleChoiceGen.Generate(Choice, Depth)
	end

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
		return SimpleChoiceGen.Generate(Choice, Depth)
	end

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		return SimpleChoiceGen.Generate(Choice, Depth)
	end

	local HasConditions = Choice.Conditions and #Choice.Conditions > 0
	local HasSkillCheck = Choice.SkillCheck ~= nil
	local HasQuestTurnIn = Choice.QuestTurnIn ~= nil
	local HasSubChoices = Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0

	if HasQuestTurnIn then
		return QuestGen.GenerateTurnIn(Choice, Depth)
	end

	if HasSkillCheck and HasConditions then
		return SkillCheckGen.GenerateConditional(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	end

	if HasSkillCheck then
		return SkillCheckGen.Generate(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	end

	if HasConditions then
		return ConditionalGen.Generate(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	end

	if HasSubChoices then
		return NestedChoiceGen.GenerateBranching(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	end

	return SimpleChoiceGen.Generate(Choice, Depth)
end

function CodeGenerator.GenerateNestedChoiceRecursive(Choice: DialogChoice, Depth: number): string
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
		return SimpleChoiceGen.GenerateNested(Choice, Depth)
	end

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
		return SimpleChoiceGen.GenerateNested(Choice, Depth)
	end

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		return SimpleChoiceGen.GenerateNested(Choice, Depth)
	end

	local HasConditions = Choice.Conditions and #Choice.Conditions > 0
	local HasSkillCheck = Choice.SkillCheck ~= nil
	local HasQuestTurnIn = Choice.QuestTurnIn ~= nil
	local HasSubChoices = Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0

	if HasQuestTurnIn then
		return QuestGen.GenerateTurnInNested(Choice, Depth)
	end

	if HasSkillCheck and HasConditions then
		return SkillCheckGen.GenerateConditionalNested(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	end

	if HasSkillCheck then
		return SkillCheckGen.GenerateNested(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	end

	if HasConditions then
		return ConditionalGen.GenerateNested(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	end

	if HasSubChoices or (Choice.ResponseNode and Choice.ResponseNode.ResponseType and Choice.ResponseNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE) then
		return NestedChoiceGen.GenerateNested(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	else
		return SimpleChoiceGen.GenerateNested(Choice, Depth)
	end
end

return CodeGenerator