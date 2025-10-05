--!strict
local DialogTree = require(script.Parent.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local CodeLibrary = script.Parent.Parent.CodeLibrary
local GreetingGen = require(CodeLibrary.GreetingGenerator)
local SimpleChoiceGen = require(CodeLibrary.SimpleChoiceGenerator)
local NestedChoiceGen = require(CodeLibrary.NestedChoiceGenerator)
local SkillCheckGen = require(CodeLibrary.SkillCheckGenerator)
local ConditionalGen = require(CodeLibrary.ConditionalGenerator)
local QuestGen = require(CodeLibrary.QuestGenerator)

local CodeGenerator = {}

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
	local HasSubChoices = Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0

	if HasSubChoices then
		return NestedChoiceGen.GenerateNested(Choice, Depth, CodeGenerator.GenerateNestedChoiceRecursive)
	else
		return SimpleChoiceGen.GenerateNested(Choice, Depth)
	end
end

return CodeGenerator