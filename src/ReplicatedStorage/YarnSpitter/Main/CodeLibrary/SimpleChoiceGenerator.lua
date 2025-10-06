--!strict
local Helpers = require(script.Parent.Helpers)

local SimpleChoiceGenerator = {}

function SimpleChoiceGenerator.Generate(Choice: any, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.CreateSimpleChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
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

function SimpleChoiceGenerator.GenerateNested(Choice: any, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "DialogHelpers.CreateSimpleChoice(\n"
	Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\"\n"
	else
		Code = Code .. Indent .. "\t\"...\",\n"
		Code = Code .. Indent .. "\t\"response\"\n"
	end

	Code = Code .. Indent .. "),\n"
	return Code
end

return SimpleChoiceGenerator