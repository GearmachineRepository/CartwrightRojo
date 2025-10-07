--!strict
local Helpers = require(script.Parent.Helpers)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

local SimpleChoiceGenerator = {}

function SimpleChoiceGenerator.Generate(Choice: any, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)

	-- Handle End Dialog - creates a choice that closes dialog immediately
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
		local Code = Indent .. "table.insert(Choices, {\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = nil\n"
		Code = Code .. Indent .. "})\n\n"
		return Code
	end

	-- Skip generating code for Return to Start choices (handled elsewhere)
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
		return ""
	end

	-- Skip generating code for Return to Node choices (handled elsewhere)
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		return ""
	end

	local Code = Indent .. "table.insert(Choices, DialogHelpers.CreateSimpleChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\""

		local HasFlags = Choice.SetFlags and #Choice.SetFlags > 0
		local HasCommand = Choice.Command and Choice.Command ~= ""

		if HasFlags or HasCommand then
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
				Code = Code .. Indent .. "\t{" .. Helpers.GenerateFlagsArray(Choice.SetFlags) .. "}"
			end
		end
	end

	Code = Code .. "\n" .. Indent .. "))\n\n"
	return Code
end

function SimpleChoiceGenerator.GenerateNested(Choice: any, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)

	-- Handle End Dialog - creates a choice that closes dialog immediately
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.END_DIALOG then
		local Code = Indent .. "{\n"
		Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\tResponse = nil\n"
		Code = Code .. Indent .. "},\n"
		return Code
	end

	-- Skip generating code for Return to Start choices
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_START then
		return ""
	end

	-- Skip generating code for Return to Node choices
	if Choice.ResponseType == DialogTree.RESPONSE_TYPES.RETURN_TO_NODE then
		return ""
	end

	local Code = Indent .. "DialogHelpers.CreateSimpleChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\"\n"
	end

	Code = Code .. Indent .. "),\n"
	return Code
end

return SimpleChoiceGenerator