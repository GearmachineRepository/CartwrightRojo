--!strict
local Helpers = require(script.Parent.Helpers)

local SkillCheckGenerator = {}

function SkillCheckGenerator.Generate(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	if not Choice.SkillCheck then
		return ""
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateSkillCheck({\n"
	Code = Code .. Indent .. "\tSkill = \"" .. Choice.SkillCheck.Skill .. "\",\n"
	Code = Code .. Indent .. "\tDifficulty = " .. tostring(Choice.SkillCheck.Difficulty) .. ",\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.SkillCheck.SuccessNode then
		Code = Code .. Indent .. "\tSuccessResponse = \"" .. Helpers.EscapeString(Choice.SkillCheck.SuccessNode.Text) .. "\",\n"
		Code = Code .. Indent .. "\tSuccessChoices = {\n"
		if Choice.SkillCheck.SuccessNode.Choices and #Choice.SkillCheck.SuccessNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.SuccessNode.Choices) do
				Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
			end
		end
		Code = Code .. Indent .. "\t},\n"

		if Choice.SetFlags and #Choice.SetFlags > 0 then
			Code = Code .. Indent .. "\tSuccessFlags = {" .. Helpers.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
		end
	end

	if Choice.SkillCheck.FailureNode then
		Code = Code .. Indent .. "\tFailureResponse = \"" .. Helpers.EscapeString(Choice.SkillCheck.FailureNode.Text) .. "\",\n"
		Code = Code .. Indent .. "\tFailureChoices = {\n"
		if Choice.SkillCheck.FailureNode.Choices and #Choice.SkillCheck.FailureNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.FailureNode.Choices) do
				Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
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

function SkillCheckGenerator.GenerateConditional(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	if not Choice.SkillCheck then
		return ""
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateConditionalChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
	Code = Code .. Indent .. "\tResponseText = \"\",\n"
	Code = Code .. Indent .. "\tConditions = {\n"

	for _, Condition in ipairs(Choice.Conditions) do
		Code = Code .. Helpers.GenerateCondition(Condition, Depth + 2)
	end

	Code = Code .. Indent .. "\t},\n"
	Code = Code .. Indent .. "\tSubChoices = {\n"
	Code = Code .. Indent .. "\t\tDialogHelpers.Advanced.CreateSkillCheck({\n"
	Code = Code .. Indent .. "\t\t\tSkill = \"" .. Choice.SkillCheck.Skill .. "\",\n"
	Code = Code .. Indent .. "\t\t\tDifficulty = " .. tostring(Choice.SkillCheck.Difficulty) .. ",\n"
	Code = Code .. Indent .. "\t\t\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.SkillCheck.SuccessNode then
		Code = Code .. Indent .. "\t\t\tSuccessResponse = \"" .. Helpers.EscapeString(Choice.SkillCheck.SuccessNode.Text) .. "\",\n"
		Code = Code .. Indent .. "\t\t\tSuccessChoices = {\n"
		if Choice.SkillCheck.SuccessNode.Choices and #Choice.SkillCheck.SuccessNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.SuccessNode.Choices) do
				Code = Code .. GenerateRecursive(SubChoice, Depth + 4)
			end
		end
		Code = Code .. Indent .. "\t\t\t},\n"

		if Choice.SetFlags and #Choice.SetFlags > 0 then
			Code = Code .. Indent .. "\t\t\tSuccessFlags = {" .. Helpers.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
		end
	end

	if Choice.SkillCheck.FailureNode then
		Code = Code .. Indent .. "\t\t\tFailureResponse = \"" .. Helpers.EscapeString(Choice.SkillCheck.FailureNode.Text) .. "\",\n"
		Code = Code .. Indent .. "\t\t\tFailureChoices = {\n"
		if Choice.SkillCheck.FailureNode.Choices and #Choice.SkillCheck.FailureNode.Choices > 0 then
			for _, SubChoice in ipairs(Choice.SkillCheck.FailureNode.Choices) do
				Code = Code .. GenerateRecursive(SubChoice, Depth + 4)
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

return SkillCheckGenerator