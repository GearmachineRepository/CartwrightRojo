--!strict
local Helpers = require(script.Parent.Parent.Helpers)
local DialogTree = require(script.Parent.Parent.Parent.Core.DialogTree)

local SkillCheckGenerator = {}

local function GenerateNodeWithResponseType(Node: any, Depth: number, GenerateRecursive: (any, number) -> string, _: boolean?): string
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
		local SuccessNode = Choice.SkillCheck.SuccessNode

		if SuccessNode.ResponseType and SuccessNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
			Code = Code .. Indent .. "\tSuccessResponse = " .. GenerateNodeWithResponseType(SuccessNode, Depth + 1, GenerateRecursive) .. ",\n"

			if SuccessNode.SetFlags and #SuccessNode.SetFlags > 0 then
				Code = Code .. Indent .. "\tSuccessFlags = {" .. Helpers.GenerateFlagsArray(SuccessNode.SetFlags) .. "},\n"
			end
		else
			Code = Code .. Indent .. "\tSuccessResponse = \"" .. Helpers.EscapeString(SuccessNode.Text) .. "\",\n"

			if SuccessNode.Choices and #SuccessNode.Choices > 0 then
				Code = Code .. Indent .. "\tSuccessChoices = {\n"
				for _, SubChoice in ipairs(SuccessNode.Choices) do
					Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
				end
				Code = Code .. Indent .. "\t},\n"
			end

			if SuccessNode.SetFlags and #SuccessNode.SetFlags > 0 then
				Code = Code .. Indent .. "\tSuccessFlags = {" .. Helpers.GenerateFlagsArray(SuccessNode.SetFlags) .. "},\n"
			end
		end
	end

	if Choice.SkillCheck.FailureNode then
		local FailureNode = Choice.SkillCheck.FailureNode

		if FailureNode.ResponseType and FailureNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
			Code = Code .. Indent .. "\tFailureResponse = " .. GenerateNodeWithResponseType(FailureNode, Depth + 1, GenerateRecursive) .. ",\n"
		else
			Code = Code .. Indent .. "\tFailureResponse = \"" .. Helpers.EscapeString(FailureNode.Text) .. "\",\n"

			if FailureNode.Choices and #FailureNode.Choices > 0 then
				Code = Code .. Indent .. "\tFailureChoices = {\n"
				for _, SubChoice in ipairs(FailureNode.Choices) do
					Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
				end
				Code = Code .. Indent .. "\t},\n"
			end

			if FailureNode.SetFlags and #FailureNode.SetFlags > 0 then
				Code = Code .. Indent .. "\tFailureFlags = {" .. Helpers.GenerateFlagsArray(FailureNode.SetFlags) .. "},\n"
			end
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
		local SuccessNode = Choice.SkillCheck.SuccessNode

		if SuccessNode.ResponseType and SuccessNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
			Code = Code .. Indent .. "\t\t\tSuccessResponse = " .. GenerateNodeWithResponseType(SuccessNode, Depth + 2, GenerateRecursive) .. ",\n"
		else
			Code = Code .. Indent .. "\t\t\tSuccessResponse = \"" .. Helpers.EscapeString(SuccessNode.Text) .. "\",\n"

			if SuccessNode.Choices and #SuccessNode.Choices > 0 then
				Code = Code .. Indent .. "\t\t\tSuccessChoices = {\n"
				for _, SubChoice in ipairs(SuccessNode.Choices) do
					Code = Code .. GenerateRecursive(SubChoice, Depth + 4)
				end
				Code = Code .. Indent .. "\t\t\t},\n"
			end

			if SuccessNode.SetFlags and #SuccessNode.SetFlags > 0 then
				Code = Code .. Indent .. "\t\t\tSuccessFlags = {" .. Helpers.GenerateFlagsArray(SuccessNode.SetFlags) .. "},\n"
			end
		end
	end

	if Choice.SkillCheck.FailureNode then
		local FailureNode = Choice.SkillCheck.FailureNode

		if FailureNode.ResponseType and FailureNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
			Code = Code .. Indent .. "\t\t\tFailureResponse = " .. GenerateNodeWithResponseType(FailureNode, Depth + 2, GenerateRecursive) .. ",\n"
		else
			Code = Code .. Indent .. "\t\t\tFailureResponse = \"" .. Helpers.EscapeString(FailureNode.Text) .. "\",\n"

			if FailureNode.Choices and #FailureNode.Choices > 0 then
				Code = Code .. Indent .. "\t\t\tFailureChoices = {\n"
				for _, SubChoice in ipairs(FailureNode.Choices) do
					Code = Code .. GenerateRecursive(SubChoice, Depth + 4)
				end
				Code = Code .. Indent .. "\t\t\t},\n"
			end

			if FailureNode.SetFlags and #FailureNode.SetFlags > 0 then
				Code = Code .. Indent .. "\t\t\tFailureFlags = {" .. Helpers.GenerateFlagsArray(FailureNode.SetFlags) .. "},\n"
			end
		end
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
		local SuccessNode = Choice.SkillCheck.SuccessNode

		if SuccessNode.ResponseType and SuccessNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
			Code = Code .. Indent .. "\tSuccessResponse = " .. GenerateNodeWithResponseType(SuccessNode, Depth + 1, GenerateRecursive) .. ",\n"
		else
			Code = Code .. Indent .. "\tSuccessResponse = \"" .. Helpers.EscapeString(SuccessNode.Text) .. "\",\n"

			if SuccessNode.Choices and #SuccessNode.Choices > 0 then
				Code = Code .. Indent .. "\tSuccessChoices = {\n"
				for _, SubChoice in ipairs(SuccessNode.Choices) do
					Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
				end
				Code = Code .. Indent .. "\t},\n"
			end

			if SuccessNode.SetFlags and #SuccessNode.SetFlags > 0 then
				Code = Code .. Indent .. "\tSuccessFlags = {" .. Helpers.GenerateFlagsArray(SuccessNode.SetFlags) .. "},\n"
			end
		end
	end

	if Choice.SkillCheck.FailureNode then
		local FailureNode = Choice.SkillCheck.FailureNode

		if FailureNode.ResponseType and FailureNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
			Code = Code .. Indent .. "\tFailureResponse = " .. GenerateNodeWithResponseType(FailureNode, Depth + 1, GenerateRecursive) .. ",\n"
		else
			Code = Code .. Indent .. "\tFailureResponse = \"" .. Helpers.EscapeString(FailureNode.Text) .. "\",\n"

			if FailureNode.Choices and #FailureNode.Choices > 0 then
				Code = Code .. Indent .. "\tFailureChoices = {\n"
				for _, SubChoice in ipairs(FailureNode.Choices) do
					Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
				end
				Code = Code .. Indent .. "\t},\n"
			end

			if FailureNode.SetFlags and #FailureNode.SetFlags > 0 then
				Code = Code .. Indent .. "\tFailureFlags = {" .. Helpers.GenerateFlagsArray(FailureNode.SetFlags) .. "},\n"
			end
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
		local SuccessNode = Choice.SkillCheck.SuccessNode

		if SuccessNode.ResponseType and SuccessNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
			Code = Code .. Indent .. "\t\t\tSuccessResponse = " .. GenerateNodeWithResponseType(SuccessNode, Depth + 2, GenerateRecursive) .. ",\n"
		else
			Code = Code .. Indent .. "\t\t\tSuccessResponse = \"" .. Helpers.EscapeString(SuccessNode.Text) .. "\",\n"

			if SuccessNode.Choices and #SuccessNode.Choices > 0 then
				Code = Code .. Indent .. "\t\t\tSuccessChoices = {\n"
				for _, SubChoice in ipairs(SuccessNode.Choices) do
					Code = Code .. GenerateRecursive(SubChoice, Depth + 4)
				end
				Code = Code .. Indent .. "\t\t\t},\n"
			end

			if SuccessNode.SetFlags and #SuccessNode.SetFlags > 0 then
				Code = Code .. Indent .. "\t\t\tSuccessFlags = {" .. Helpers.GenerateFlagsArray(SuccessNode.SetFlags) .. "},\n"
			end
		end
	end

	if Choice.SkillCheck.FailureNode then
		local FailureNode = Choice.SkillCheck.FailureNode

		if FailureNode.ResponseType and FailureNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
			Code = Code .. Indent .. "\t\t\tFailureResponse = " .. GenerateNodeWithResponseType(FailureNode, Depth + 2, GenerateRecursive) .. ",\n"
		else
			Code = Code .. Indent .. "\t\t\tFailureResponse = \"" .. Helpers.EscapeString(FailureNode.Text) .. "\",\n"

			if FailureNode.Choices and #FailureNode.Choices > 0 then
				Code = Code .. Indent .. "\t\t\tFailureChoices = {\n"
				for _, SubChoice in ipairs(FailureNode.Choices) do
					Code = Code .. GenerateRecursive(SubChoice, Depth + 4)
				end
				Code = Code .. Indent .. "\t\t\t},\n"
			end

			if FailureNode.SetFlags and #FailureNode.SetFlags > 0 then
				Code = Code .. Indent .. "\t\t\tFailureFlags = {" .. Helpers.GenerateFlagsArray(FailureNode.SetFlags) .. "},\n"
			end
		end
	end

	Code = Code .. Indent .. "\t\t})\n"
	Code = Code .. Indent .. "\t},\n"
	Code = Code .. Indent .. "}),\n\n"
	return Code
end

return SkillCheckGenerator