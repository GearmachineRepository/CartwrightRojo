--!strict
local Helpers = require(script.Parent.Helpers)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

local SimpleChoiceGenerator = {}

local function GenerateResponseNodeWithType(ResponseNode: any, Depth: number, IncludeFlags: boolean?): string
	if not ResponseNode then
		return "nil"
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = "{\n"

	Code = Code .. Indent .. "\tId = \"" .. ResponseNode.Id .. "\",\n"
	Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(ResponseNode.Text) .. "\",\n"

	if ResponseNode.ResponseType and ResponseNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE then
		if ResponseNode.ResponseType == DialogTree.RESPONSE_TYPES.CONTINUE_TO_RESPONSE and ResponseNode.NextResponseNode then
			Code = Code .. Indent .. "\tResponseType = \"continue_to_response\",\n"
			Code = Code .. Indent .. "\tNextResponseNode = " .. GenerateResponseNodeWithType(ResponseNode.NextResponseNode, Depth + 1, IncludeFlags) .. ",\n"
		elseif ResponseNode.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
			Code = Code .. Indent .. "\tResponseType = \"return_to_start\",\n"
		elseif ResponseNode.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE and ResponseNode.ReturnToNodeId then
			Code = Code .. Indent .. "\tResponseType = \"return_to_node\",\n"
			Code = Code .. Indent .. "\tReturnToNodeId = \"" .. ResponseNode.ReturnToNodeId .. "\",\n"
		elseif ResponseNode.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
			Code = Code .. Indent .. "\tResponseType = \"end_dialog\",\n"
		end
	end

	if IncludeFlags and ResponseNode.SetFlags and #ResponseNode.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. Helpers.GenerateFlagsArray(ResponseNode.SetFlags) .. "},\n"
	end

	if ResponseNode.Choices and #ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tChoices = {}\n"
	end

	Code = Code .. Indent .. "}"
	return Code
end

function SimpleChoiceGenerator.Generate(Choice: any, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
		local Code = Indent .. "table.insert(Choices, DialogHelpers.CreateSimpleChoice(\n"
		Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tnil,\n"
		Code = Code .. Indent .. "\tnil\n"
		Code = Code .. Indent .. "))\n\n"
		return Code
	end

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
		local Code = Indent .. "table.insert(Choices, {\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = nil,\n"
		Code = Code .. Indent .. "\tReturnToNodeId = \"start\"\n"
		Code = Code .. Indent .. "})\n\n"
		return Code
	end

	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		local TargetNodeId = Choice.ReturnToNodeId or "start"
		local Code = Indent .. "table.insert(Choices, {\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = nil,\n"
		Code = Code .. Indent .. "\tReturnToNodeId = \"" .. TargetNodeId .. "\"\n"
		Code = Code .. Indent .. "})\n\n"
		return Code
	end

	if Choice.ResponseNode and (Choice.ResponseNode.ResponseType and Choice.ResponseNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE) then
		local HasFlags = Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0
		local Code = Indent .. "table.insert(Choices, {\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = " .. GenerateResponseNodeWithType(Choice.ResponseNode, Depth + 1, HasFlags) .. "\n"
		Code = Code .. Indent .. "})\n\n"
		return Code
	end

	local Code = Indent .. "table.insert(Choices, DialogHelpers.CreateSimpleChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		local HasFlags = Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0
		local HasCommand = Choice.Command and Choice.Command ~= ""

		if HasFlags then
			Code = Code .. Indent .. "\t{\n"
			Code = Code .. Indent .. "\t\tId = \"" .. Choice.ResponseNode.Id .. "\",\n"
			Code = Code .. Indent .. "\t\tText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
			Code = Code .. Indent .. "\t\tSetFlags = {" .. Helpers.GenerateFlagsArray(Choice.ResponseNode.SetFlags) .. "}\n"
			Code = Code .. Indent .. "\t},\n"
			Code = Code .. Indent .. "\tnil"
		else
			Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
			Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\""
		end

		if HasCommand then
			Code = Code .. ",\n"
			Code = Code .. Indent .. "\tfunction(Plr: Player)\n"
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

function SimpleChoiceGenerator.GenerateNested(Choice: any, Depth: number): string
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

	if Choice.ResponseNode and (Choice.ResponseNode.ResponseType and Choice.ResponseNode.ResponseType ~= DialogTree.RESPONSE_TYPES.DEFAULT_RESPONSE) then
		local HasFlags = Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0
		local Code = Indent .. "{\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = " .. GenerateResponseNodeWithType(Choice.ResponseNode, Depth + 1, HasFlags) .. "\n"
		Code = Code .. Indent .. "},\n\n"
		return Code
	end

	local Code = Indent .. "DialogHelpers.CreateSimpleChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		local HasFlags = Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0
		local HasCommand = Choice.Command and Choice.Command ~= ""

		if HasFlags then
			Code = Code .. Indent .. "\t{\n"
			Code = Code .. Indent .. "\t\tId = \"" .. Choice.ResponseNode.Id .. "\",\n"
			Code = Code .. Indent .. "\t\tText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
			Code = Code .. Indent .. "\t\tSetFlags = {" .. Helpers.GenerateFlagsArray(Choice.ResponseNode.SetFlags) .. "}\n"
			Code = Code .. Indent .. "\t},\n"
			Code = Code .. Indent .. "\tnil"
		else
			Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
			Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\""
		end

		if HasCommand then
			Code = Code .. ",\n"
			Code = Code .. Indent .. "\tfunction(Plr: Player)\n"
			Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
			Code = Code .. Indent .. "\tend"
		end
	else
		Code = Code .. Indent .. "\t\"...\",\n"
		Code = Code .. Indent .. "\t\"response\"\n"
	end

	Code = Code .. "\n" .. Indent .. "),\n\n"
	return Code
end

return SimpleChoiceGenerator