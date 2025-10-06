--!strict
local Helpers = require(script.Parent.Helpers)

local NestedChoiceGenerator = {}

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

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. ",\n" .. Indent .. "\tfunction(Plr: Player)\n"
		Code = Code .. Indent .. "\t\t" .. Choice.Command:gsub("\n", "\n" .. Indent .. "\t\t") .. "\n"
		Code = Code .. Indent .. "\tend"
	end

	Code = Code .. "\n" .. Indent .. "))\n\n"
	return Code
end

function NestedChoiceGenerator.GenerateNested(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	local Indent = Helpers.GetIndent(Depth)
	local HasSubChoices = Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0

	if HasSubChoices then
		local Code = Indent .. "DialogHelpers.CreateNestedChoice(\n"
		Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
		Code = Code .. Indent .. "\t\"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
		Code = Code .. Indent .. "\t{\n"

		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end

		Code = Code .. Indent .. "\t},\n"
		Code = Code .. Indent .. "\t\"" .. Choice.ResponseNode.Id .. "\"\n"
		Code = Code .. Indent .. "),\n"
		return Code
	else
		local SimpleChoiceGen = require(script.Parent.SimpleChoiceGenerator)
		return SimpleChoiceGen.GenerateNested(Choice, Depth)
	end
end

return NestedChoiceGenerator