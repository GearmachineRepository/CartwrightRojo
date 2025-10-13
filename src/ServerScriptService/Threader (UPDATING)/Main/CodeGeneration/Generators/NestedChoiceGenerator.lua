--!strict
local Helpers = require(script.Parent.Parent.Helpers)
local DialogTree = require(script.Parent.Parent.Parent.Core.DialogTree)

local NestedChoiceGenerator = {}

local function GenerateResponseNodeWithType(ResponseNode: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = "{\n"

	Code = Code .. Indent .. "\tId = \"" .. ResponseNode.Id .. "\",\n"
	Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(ResponseNode.Text) .. "\",\n"

	if ResponseNode.ResponseType and ResponseNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
		if ResponseNode.ResponseType == DialogTree.RESPONSE_TYPES.CONTINUE_TO_RESPONSE and ResponseNode.NextResponseNode then
			Code = Code .. Indent .. "\tResponseType = \"continue_to_response\",\n"
			Code = Code .. Indent .. "\tNextResponseNode = " .. GenerateResponseNodeWithType(ResponseNode.NextResponseNode, Depth + 1, GenerateRecursive) .. ",\n"
		elseif ResponseNode.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
			Code = Code .. Indent .. "\tResponseType = \"return_to_start\",\n"
		elseif ResponseNode.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE and ResponseNode.ReturnToNodeId then
			Code = Code .. Indent .. "\tResponseType = \"return_to_node\",\n"
			Code = Code .. Indent .. "\tReturnToNodeId = \"" .. ResponseNode.ReturnToNodeId .. "\",\n"
		elseif ResponseNode.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
			Code = Code .. Indent .. "\tResponseType = \"end_dialog\",\n"
		end
	end

	if ResponseNode.Choices and #ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tChoices = {\n"
		for _, SubChoice in ipairs(ResponseNode.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t}\n"
	end

	Code = Code .. Indent .. "}"
	return Code
end

function NestedChoiceGenerator.GenerateBranching(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	if not Choice.ResponseNode then
		local SimpleChoiceGen = require(script.Parent.SimpleChoiceGenerator)
		return SimpleChoiceGen.Generate(Choice, Depth)
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.CreateBranchingChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
	Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
	Code = Code .. Indent .. "\t{\n"

	if Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end
	end

	Code = Code .. Indent .. "\t},\n"
	Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\""

	local HasCommand = Choice.Command and Choice.Command ~= ""
	local HasFlags = Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0

	if HasCommand or HasFlags then
		Code = Code .. ",\n"

		if HasCommand then
			Code = Code .. Indent .. "\tfunction(Plr: Player)\n"
			Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
			Code = Code .. Indent .. "\tend"
		else
			Code = Code .. Indent .. "\tnil"
		end

		if HasFlags then
			Code = Code .. ",\n"
			Code = Code .. Indent .. "\t{" .. Helpers.GenerateFlagsArray(Choice.ResponseNode.SetFlags) .. "}"
		end
	end

	Code = Code .. "\n" .. Indent .. "))\n\n"
	return Code
end

function NestedChoiceGenerator.GenerateNested(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	local Indent = Helpers.GetIndent(Depth)

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
		local Code = Indent .. "{\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = nil\n"
		Code = Code .. Indent .. "},\n\n"
		return Code
	end

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
		local Code = Indent .. "{\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = nil,\n"
		Code = Code .. Indent .. "\tReturnToNodeId = \"start\"\n"
		Code = Code .. Indent .. "},\n\n"
		return Code
	end

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		local TargetNodeId = Choice.ReturnToNodeId or "start"
		local Code = Indent .. "{\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = nil,\n"
		Code = Code .. Indent .. "\tReturnToNodeId = \"" .. TargetNodeId .. "\"\n"
		Code = Code .. Indent .. "},\n\n"
		return Code
	end

	local HasSubChoices = Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0

	if HasSubChoices or (Choice.ResponseNode and Choice.ResponseNode.ResponseType and Choice.ResponseNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE) then
		local Code = Indent .. "{\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = " .. GenerateResponseNodeWithType(Choice.ResponseNode, Depth + 1, GenerateRecursive) .. "\n"
		Code = Code .. Indent .. "},\n\n"
		return Code
	else
		local SimpleChoiceGen = require(script.Parent.SimpleChoiceGenerator)
		return SimpleChoiceGen.GenerateNested(Choice, Depth)
	end
end

return NestedChoiceGenerator