--!strict
local DialogTree = require(script.Parent.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

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

	if Tree.Greetings and #Tree.Greetings > 0 then
		Code = Code .. CodeGenerator.GenerateConditionalGreeting(Tree)
	else
		Code = Code .. "\tlocal Greeting = \"" .. Tree.Text:gsub('"', '\\"') .. "\"\n\n"
	end

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

function CodeGenerator.GenerateConditionalGreeting(Tree: DialogNode): string
	local Code = ""

	for Index, Greeting in ipairs(Tree.Greetings or {}) do
		local VarName = Greeting.ConditionType:gsub("%s+", "") .. Index
		Code = Code .. "\tlocal " .. VarName .. " = "

		if Greeting.ConditionType == "HasQuest" then
			Code = Code .. "DialogBuilder.HasActiveQuest(Player, \"" .. Greeting.ConditionValue .. "\")\n"
		elseif Greeting.ConditionType == "CompletedQuest" then
			Code = Code .. "DialogBuilder.HasCompletedQuest(Player, \"" .. Greeting.ConditionValue .. "\")\n"
		elseif Greeting.ConditionType == "DialogFlag" then
			Code = Code .. "DialogConditions.Check(Player, {Type = \"DialogFlag\", Value = \"" .. Greeting.ConditionValue .. "\"})\n"
		else
			Code = Code .. "false\n"
		end
	end

	Code = Code .. "\n\tlocal Greeting = DialogHelpers.GetConditionalGreeting({\n"

	for Index, Greeting in ipairs(Tree.Greetings or {}) do
		local VarName = Greeting.ConditionType:gsub("%s+", "") .. Index
		Code = Code .. "\t\t{" .. VarName .. ", \"" .. Greeting.GreetingText:gsub('"', '\\"') .. "\"},\n"
	end

	Code = Code .. "\t}, \"" .. Tree.Text:gsub('"', '\\"') .. "\")\n\n"

	return Code
end

function CodeGenerator.GenerateChoiceCode(Choice: DialogChoice, Depth: number): string
	local HasConditions = Choice.Conditions and #Choice.Conditions > 0
	local HasSkillCheck = Choice.SkillCheck ~= nil
	local HasQuestTurnIn = Choice.QuestTurnIn ~= nil
	local HasSubChoices = Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0

	if HasQuestTurnIn then
		return CodeGenerator.GenerateQuestTurnIn(Choice, Depth)
	end

	if HasSkillCheck and HasConditions then
		return CodeGenerator.GenerateConditionalSkillCheck(Choice, Depth)
	end

	if HasSkillCheck then
		return CodeGenerator.GenerateSkillCheck(Choice, Depth)
	end

	if HasConditions then
		return CodeGenerator.GenerateConditionalChoice(Choice, Depth)
	end

	if HasSubChoices then
		return CodeGenerator.GenerateBranchingChoice(Choice, Depth)
	end

	return CodeGenerator.GenerateSimpleChoice(Choice, Depth)
end

function CodeGenerator.GenerateSkillCheck(Choice: DialogChoice, Depth: number): string
	if not Choice.SkillCheck then return "" end

	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateSkillCheck({\n"
	Code = Code .. Indent .. "\tSkill = \"" .. Choice.SkillCheck.Skill .. "\",\n"
	Code = Code .. Indent .. "\tDifficulty = " .. tostring(Choice.SkillCheck.Difficulty) .. ",\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.SkillCheck.SuccessNode then
		Code = Code .. Indent .. "\tSuccessResponse = \"" .. Choice.SkillCheck.SuccessNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\tSuccessChoices = {\n"
		if Choice.SkillCheck.SuccessNode.Choices and #Choice.SkillCheck.SuccessNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.SuccessNode.Choices) do
				Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 2)
			end
		end
		Code = Code .. Indent .. "\t},\n"

		if Choice.SetFlags and #Choice.SetFlags > 0 then
			Code = Code .. Indent .. "\tSuccessFlags = {" .. CodeGenerator.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
		end
	end

	if Choice.SkillCheck.FailureNode then
		Code = Code .. Indent .. "\tFailureResponse = \"" .. Choice.SkillCheck.FailureNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\tFailureChoices = {\n"
		if Choice.SkillCheck.FailureNode.Choices and #Choice.SkillCheck.FailureNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.FailureNode.Choices) do
				Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 2)
			end
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Indent .. "\tSuccessCommand = function(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend,\n"
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function CodeGenerator.GenerateConditionalSkillCheck(Choice: DialogChoice, Depth: number): string
	if not Choice.SkillCheck then return "" end

	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateConditionalChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"
	Code = Code .. Indent .. "\tResponseText = \"\",\n"
	Code = Code .. Indent .. "\tConditions = {\n"

	for _, Condition in ipairs(Choice.Conditions) do
		Code = Code .. CodeGenerator.GenerateCondition(Condition, Depth + 2)
	end

	Code = Code .. Indent .. "\t},\n"
	Code = Code .. Indent .. "\tSubChoices = {\n"
	Code = Code .. Indent .. "\t\tDialogHelpers.Advanced.CreateSkillCheck({\n"
	Code = Code .. Indent .. "\t\t\tSkill = \"" .. Choice.SkillCheck.Skill .. "\",\n"
	Code = Code .. Indent .. "\t\t\tDifficulty = " .. tostring(Choice.SkillCheck.Difficulty) .. ",\n"
	Code = Code .. Indent .. "\t\t\tButtonText = \"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.SkillCheck.SuccessNode then
		Code = Code .. Indent .. "\t\t\tSuccessResponse = \"" .. Choice.SkillCheck.SuccessNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t\t\tSuccessChoices = {\n"
		if Choice.SkillCheck.SuccessNode.Choices and #Choice.SkillCheck.SuccessNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.SuccessNode.Choices) do
				Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 4)
			end
		end
		Code = Code .. Indent .. "\t\t\t},\n"

		if Choice.SetFlags and #Choice.SetFlags > 0 then
			Code = Code .. Indent .. "\t\t\tSuccessFlags = {" .. CodeGenerator.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
		end
	end

	if Choice.SkillCheck.FailureNode then
		Code = Code .. Indent .. "\t\t\tFailureResponse = \"" .. Choice.SkillCheck.FailureNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t\t\tFailureChoices = {\n"
		if Choice.SkillCheck.FailureNode.Choices and #Choice.SkillCheck.FailureNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.FailureNode.Choices) do
				Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 4)
			end
		end
		Code = Code .. Indent .. "\t\t\t},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Indent .. "\t\t\tSuccessCommand = function(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t\t\t") .. "\n"
		Code = Code .. Indent .. "\t\t\tend,\n"
	end

	Code = Code .. Indent .. "\t\t})\n"
	Code = Code .. Indent .. "\t},\n"
	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function CodeGenerator.GenerateConditionalChoice(Choice: DialogChoice, Depth: number): string
	if not Choice.Conditions then return "" end

	local Indent = string.rep("\t", Depth)

	local IsFlagGated = #Choice.Conditions == 1 and Choice.Conditions[1].Type == "DialogFlag"
	local IsQuestGated = #Choice.Conditions == 1 and (
		Choice.Conditions[1].Type == "HasQuest" or
		Choice.Conditions[1].Type == "CompletedQuest" or
		Choice.Conditions[1].Type == "CanTurnInQuest"
	)
	local IsReputationGated = #Choice.Conditions == 1 and Choice.Conditions[1].Type == "HasReputation"

	if IsFlagGated then
		return CodeGenerator.GenerateFlagGatedChoice(Choice, Depth)
	elseif IsQuestGated then
		return CodeGenerator.GenerateQuestGatedChoice(Choice, Depth)
	elseif IsReputationGated then
		return CodeGenerator.GenerateReputationGatedChoice(Choice, Depth)
	end

	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateConditionalChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
	end

	Code = Code .. Indent .. "\tConditions = {\n"
	for _, Condition in ipairs(Choice.Conditions) do
		Code = Code .. CodeGenerator.GenerateCondition(Condition, Depth + 2)
	end
	Code = Code .. Indent .. "\t},\n"

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.SetFlags and #Choice.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. CodeGenerator.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Indent .. "\tCommand = function(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend,\n"
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function CodeGenerator.GenerateFlagGatedChoice(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local FlagName = Choice.Conditions[1].Value

	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateFlagGatedChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
	end

	Code = Code .. Indent .. "\tRequiredFlag = \"" .. FlagName .. "\",\n"

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.SetFlags and #Choice.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. CodeGenerator.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Indent .. "\tCommand = function(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend,\n"
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function CodeGenerator.GenerateQuestGatedChoice(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local Condition = Choice.Conditions[1]
	local QuestId = Condition.Value

	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateQuestGatedChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
	end

	Code = Code .. Indent .. "\tRequiredQuest = \"" .. QuestId .. "\",\n"

	if Condition.Type == "HasQuest" then
		Code = Code .. Indent .. "\tMustBeActive = true,\n"
	elseif Condition.Type == "CanTurnInQuest" then
		Code = Code .. Indent .. "\tCanTurnIn = true,\n"
	end

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.SetFlags and #Choice.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. CodeGenerator.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Indent .. "\tCommand = function(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend,\n"
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function CodeGenerator.GenerateReputationGatedChoice(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local RepData = Choice.Conditions[1].Value

	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateReputationGatedChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
	end

	if type(RepData) == "table" then
		Code = Code .. Indent .. "\tFaction = \"" .. RepData.Faction .. "\",\n"
		Code = Code .. Indent .. "\tMinRep = " .. tostring(RepData.Min) .. ",\n"
	else
		local Parts = string.split(tostring(RepData), "/")
		if #Parts == 2 then
			Code = Code .. Indent .. "\tFaction = \"" .. Parts[1] .. "\",\n"
			Code = Code .. Indent .. "\tMinRep = " .. Parts[2] .. ",\n"
		end
	end

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.SetFlags and #Choice.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. CodeGenerator.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Indent .. "\tCommand = function(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend,\n"
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function CodeGenerator.GenerateBranchingChoice(Choice: DialogChoice, Depth: number): string
	if not Choice.ResponseNode then
		return CodeGenerator.GenerateSimpleChoice(Choice, Depth)
	end

	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.CreateBranchingChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"
	Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
	Code = Code .. Indent .. "\t{\n"

	if Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 2)
		end
	end

	Code = Code .. Indent .. "\t},\n"
	Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\""

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. ",\n" .. Indent .. "\tfunction(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend"
	end

	Code = Code .. "\n" .. Indent .. "))\n\n"
	return Code
end

function CodeGenerator.GenerateSimpleChoice(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.CreateSimpleChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\""

		if Choice.Command and Choice.Command ~= "" then
			Code = Code .. ",\n" .. Indent .. "\tfunction(Plr: Player)\n"
			Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
			Code = Code .. Indent .. "\tend"
		end
	else
		Code = Code .. Indent .. "\t\"...\",\n"
		Code = Code .. Indent .. "\t\"response\"\n"
	end

	Code = Code .. "\n" .. Indent .. "))\n\n"
	return Code
end

function CodeGenerator.GenerateNestedChoiceRecursive(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local HasSubChoices = Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0

	if HasSubChoices then
		local Code = Indent .. "DialogHelpers.CreateNestedChoice(\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t{\n"

		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. CodeGenerator.GenerateNestedChoiceRecursive(SubChoice, Depth + 2)
		end

		Code = Code .. Indent .. "\t},\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\"\n"
		Code = Code .. Indent .. "),\n"
		return Code
	else
		return CodeGenerator.GenerateNestedChoice(Choice, Depth)
	end
end

function CodeGenerator.GenerateNestedChoice(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "DialogHelpers.CreateSimpleChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\"\n"
	else
		Code = Code .. Indent .. "\t\"...\",\n"
		Code = Code .. Indent .. "\t\"nested_response\"\n"
	end

	Code = Code .. Indent .. "),\n"
	return Code
end

function CodeGenerator.GenerateCondition(Condition: DialogTree.ConditionData, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "{Type = \"" .. Condition.Type .. "\", Value = "

	if type(Condition.Value) == "string" then
		Code = Code .. "\"" .. Condition.Value .. "\""
	elseif type(Condition.Value) == "table" then
		Code = Code .. "{"
		local First = true
		for Key, Val in pairs(Condition.Value) do
			if not First then
				Code = Code .. ", "
			end
			First = false
			if type(Val) == "string" then
				Code = Code .. Key .. " = \"" .. Val .. "\""
			else
				Code = Code .. Key .. " = " .. tostring(Val)
			end
		end
		Code = Code .. "}"
	else
		Code = Code .. tostring(Condition.Value)
	end

	Code = Code .. "},\n"
	return Code
end

function CodeGenerator.GenerateFlagsArray(Flags: {string}): string
	local FlagsStr = ""
	for i, Flag in ipairs(Flags) do
		if i > 1 then
			FlagsStr = FlagsStr .. ", "
		end
		FlagsStr = FlagsStr .. '"' .. Flag .. '"'
	end
	return FlagsStr
end

function CodeGenerator.GenerateQuestTurnIn(Choice: DialogChoice, Depth: number): string
	if not Choice.QuestTurnIn then return "" end

	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "if DialogBuilder.CanTurnInQuest(Player, \"" .. Choice.QuestTurnIn.QuestId .. "\") then\n"
	Code = Code .. Indent .. "\ttable.insert(Choices, 1, {\n"
	Code = Code .. Indent .. "\t\tText = \"[QUEST] " .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"
	Code = Code .. Indent .. "\t\tResponse = {\n"
	Code = Code .. Indent .. "\t\t\tId = \"turn_in_" .. Choice.QuestTurnIn.QuestId .. "\",\n"
	Code = Code .. Indent .. "\t\t\tText = \"" .. Choice.QuestTurnIn.ResponseText:gsub('"', '\\"') .. "\",\n"
	Code = Code .. Indent .. "\t\t\tTurnInQuest = \"" .. Choice.QuestTurnIn.QuestId .. "\"\n"
	Code = Code .. Indent .. "\t\t}\n"
	Code = Code .. Indent .. "\t})\n"
	Code = Code .. Indent .. "end\n\n"
	return Code
end

return CodeGenerator