--!strict
local Helpers = require(script.Parent.Helpers)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

local SkillCheckGenerator = {}

local function GenerateNodeWithResponseType(Node: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = "{\n"

	Code = Code .. Indent .. "\tId = \"" .. Node.Id .. "\",\n"
	Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Node.Text) .. "\",\n"

	if Node.ResponseType and Node.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
		if Node.ResponseType == DialogTree.RESPONSE_TYPES.CONTINUE_TO_RESPONSE and Node.NextResponseNode then
			Code = Code .. Indent .. "\tResponseType = \"continue_to_response\",\n"
			Code = Code .. Indent .. "\tNextResponseNode = " .. GenerateNodeWithResponseType(Node.NextResponseNode, Depth + 1, GenerateRecursive) .. ",\n"
		elseif Node.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
			Code = Code .. Indent .. "\tResponseType = \"return_to_start\",\n"
		elseif Node.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE and Node.ReturnToNodeId then
			Code = Code .. Indent .. "\tResponseType = \"return_to_node\",\n"
			Code = Code .. Indent .. "\tReturnToNodeId = \"" .. Node.ReturnToNodeId .. "\",\n"
		elseif Node.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
			Code = Code .. Indent .. "\tResponseType = \"end_dialog\",\n"
		end
	end

	if Node.Choices and #Node.Choices > 0 then
		Code = Code .. Indent .. "\tChoices = {\n"
		for _, SubChoice in ipairs(Node.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t}\n"
	end

	Code = Code .. Indent .. "}"
	return Code
end

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

		if Choice.SkillCheck.SuccessNode.Choices and #Choice.SkillCheck.SuccessNode.Choices > 0 then
			Code = Code .. Indent .. "\tSuccessChoices = {\n"
			for _, SubChoice in ipairs(Choice.SkillCheck.SuccessNode.Choices) do
				Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
			end
			Code = Code .. Indent .. "\t},\n"
		end

		if Choice.SetFlags and #Choice.SetFlags > 0 then
			Code = Code .. Indent .. "\tSuccessFlags = {" .. Helpers.GenerateFlagsArray(Choice.SetFlags) .. "},\n"
		end
	end

	if Choice.SkillCheck.FailureNode then
		Code = Code .. Indent .. "\tFailureResponse = \"" .. Helpers.EscapeString(Choice.SkillCheck.FailureNode.Text) .. "\",\n"

		if Choice.SkillCheck.FailureNode.Choices and #Choice.SkillCheck.FailureNode.Choices > 0 then
			Code = Code .. Indent .. "\tFailureChoices = {\n"
			for _, SubChoice in ipairs(Choice.SkillCheck.FailureNode.Choices) do
				Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
			end
			Code = Code .. Indent .. "\t},\n"
		end
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

function SkillCheckGenerator.GenerateNested(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	if not Choice.SkillCheck then
		return ""
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "DialogHelpers.Advanced.CreateSkillCheck({\n"
	Code = Code .. Indent .. "\tSkill = \"" .. Choice.SkillCheck.Skill .. "\",\n"
	Code = Code .. Indent .. "\tDifficulty = " .. tostring(Choice.SkillCheck.Difficulty) .. ",\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.SkillCheck.SuccessNode then
		Code = Code .. Indent .. "\tSuccessResponse = \"" .. Helpers.EscapeString(Choice.SkillCheck.SuccessNode.Text) .. "\",\n"

		local HasSuccessChoices = Choice.SkillCheck.SuccessNode.Choices and #Choice.SkillCheck.SuccessNode.Choices > 0
		if HasSuccessChoices then
			Code = Code .. Indent .. "\tSuccessChoices = {\n"
			for _, SubChoice in ipairs(Choice.SkillCheck.SuccessNode.Choices) do
				Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
			end
			Code = Code .. Indent .. "\t},\n"
		end
	end

	if Choice.SkillCheck.FailureNode then
		Code = Code .. Indent .. "\tFailureResponse = \"" .. Helpers.EscapeString(Choice.SkillCheck.FailureNode.Text) .. "\",\n"

		local HasFailureChoices = Choice.SkillCheck.FailureNode.Choices and #Choice.SkillCheck.FailureNode.Choices > 0
		if HasFailureChoices then
			Code = Code .. Indent .. "\tFailureChoices = {\n"
			for _, SubChoice in ipairs(Choice.SkillCheck.FailureNode.Choices) do
				Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
			end
			Code = Code .. Indent .. "\t},\n"
		end
	end

	Code = Code .. Indent .. "}),\n\n"
	return Code
end

function SkillCheckGenerator.GenerateConditionalNested(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	if not Choice.SkillCheck then
		return ""
	end

	local Indent = Helpers.GetIndent(Depth)

	local Code = Indent .. "DialogHelpers.Advanced.CreateConditionalChoice({\n"
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

	Code = Code .. Indent .. "\t\t})\n"
	Code = Code .. Indent .. "\t},\n"
	Code = Code .. Indent .. "}),\n\n"
	return Code
end

return SkillCheckGenerator