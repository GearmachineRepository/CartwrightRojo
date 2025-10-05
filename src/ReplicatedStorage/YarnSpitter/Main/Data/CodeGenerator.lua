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
	local Choices = {}

]]

	if Tree.Choices then
		for _, Choice in ipairs(Tree.Choices) do
			Code = Code .. GenerateChoiceCode(Choice, 1)
		end
	end

	Code = Code .. [[

	local DialogTree = DialogHelpers.CreateDialogStart(
		"]] .. Tree.Text:gsub('"', '\\"') .. [[",
		Choices
	)

	return DialogBuilder.ProcessNode(Player, DialogTree)
end
]]

	return Code
end

function GenerateChoiceCode(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)

	local HasConditions = Choice.Conditions and #Choice.Conditions > 0
	local HasSkillCheck = Choice.SkillCheck ~= nil
	local HasSubChoices = Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0

	if HasSkillCheck and HasConditions then
		return GenerateConditionalSkillCheck(Choice, Depth)
	end

	if HasSkillCheck then
		return GenerateSkillCheck(Choice, Depth)
	end

	if HasConditions then
		return GenerateConditionalChoice(Choice, Depth)
	end

	if HasSubChoices then
		return GenerateBranchingChoice(Choice, Depth)
	end

	return GenerateSimpleChoice(Choice, Depth)
end

function GenerateSkillCheck(Choice: DialogChoice, Depth: number): string
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
				Code = Code .. GenerateNestedChoiceWithSubChoices(SubChoice, Depth + 2)
			end
		end
		Code = Code .. Indent .. "\t},\n"

		if Choice.SetFlags and #Choice.SetFlags > 0 then
			Code = Code .. Indent .. "\tSuccessFlags = {" .. GenerateFlagsArray(Choice.SetFlags) .. "},\n"
		end
	end

	if Choice.SkillCheck.FailureNode then
		Code = Code .. Indent .. "\tFailureResponse = \"" .. Choice.SkillCheck.FailureNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\tFailureChoices = {\n"
		if Choice.SkillCheck.FailureNode.Choices and #Choice.SkillCheck.FailureNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.FailureNode.Choices) do
				Code = Code .. GenerateNestedChoiceWithSubChoices(SubChoice, Depth + 2)
			end
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Indent .. "\tSuccessCommand = function(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend\n"
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function GenerateConditionalChoice(Choice: DialogChoice, Depth: number): string
	if not Choice.Conditions then return "" end

	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateConditionalChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
	end

	Code = Code .. Indent .. "\tConditions = {\n"
	for _, Condition in ipairs(Choice.Conditions) do
		Code = Code .. GenerateCondition(Condition, Depth + 2)
	end
	Code = Code .. Indent .. "\t},\n"

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateNestedChoiceWithSubChoices(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.SetFlags and #Choice.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. GenerateFlagsArray(Choice.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Indent .. "\tCommand = function(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend\n"
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function GenerateConditionalSkillCheck(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "if "

	if Choice.Conditions then
		for i, Condition in ipairs(Choice.Conditions) do
			if i > 1 then Code = Code .. " and " end
			Code = Code .. GenerateConditionCheck(Condition)
		end
	end

	Code = Code .. " then\n"
	Code = Code .. GenerateSkillCheck(Choice, Depth + 1)
	Code = Code .. Indent .. "end\n\n"
	return Code
end

function GenerateBranchingChoice(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.CreateBranchingChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t{\n"

		if Choice.ResponseNode.Choices then
			for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
				Code = Code .. GenerateNestedChoiceWithSubChoices(SubChoice, Depth + 2)
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
	end

	return Code
end

function GenerateSimpleChoice(Choice: DialogChoice, Depth: number): string
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

function GenerateNestedChoiceWithSubChoices(Choice: DialogChoice, Depth: number): string
	local Indent = string.rep("\t", Depth)

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		local Code = Indent .. "DialogHelpers.CreateNestedChoice(\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ButtonText:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Text:gsub('"', '\\"') .. "\",\n"
		Code = Code .. Indent .. "\t{\n"

		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateNestedChoice(SubChoice, Depth + 2)
		end

		Code = Code .. Indent .. "\t},\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\"\n"
		Code = Code .. Indent .. "),\n"
		return Code
	else
		return GenerateNestedChoice(Choice, Depth)
	end
end

function GenerateNestedChoice(Choice: DialogChoice, Depth: number): string
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

function GenerateCondition(Condition: DialogTree.ConditionData, Depth: number): string
	local Indent = string.rep("\t", Depth)
	local Code = Indent .. "{Type = \"" .. Condition.Type .. "\", Value = "

	if type(Condition.Value) == "string" then
		if Condition.Type == "HasReputation" or Condition.Type == "HasSkill" then
			local Parts = string.split(Condition.Value, "/")
			if #Parts == 2 then
				Code = Code .. "{Faction = \"" .. Parts[1] .. "\", Min = " .. Parts[2] .. "}"
			else
				Code = Code .. "\"" .. Condition.Value .. "\""
			end
		else
			Code = Code .. "\"" .. Condition.Value .. "\""
		end
	else
		Code = Code .. tostring(Condition.Value)
	end

	Code = Code .. "},\n"
	return Code
end

function GenerateConditionCheck(Condition: DialogTree.ConditionData): string
	if Condition.Type == "DialogFlag" then
		return 'DialogConditions.Check(Player, {Type = "DialogFlag", Value = "' .. Condition.Value .. '"})'
	elseif Condition.Type == "HasQuest" then
		return 'DialogBuilder.HasActiveQuest(Player, "' .. Condition.Value .. '")'
	elseif Condition.Type == "CompletedQuest" then
		return 'DialogBuilder.HasCompletedQuest(Player, "' .. Condition.Value .. '")'
	else
		return 'DialogConditions.Check(Player, {Type = "' .. Condition.Type .. '", Value = "' .. Condition.Value .. '"})'
	end
end

function GenerateFlagsArray(Flags: {string}): string
	local FlagsStr = ""
	for i, Flag in ipairs(Flags) do
		if i > 1 then FlagsStr = FlagsStr .. ", " end
		FlagsStr = FlagsStr .. '"' .. Flag .. '"'
	end
	return FlagsStr
end

return CodeGenerator