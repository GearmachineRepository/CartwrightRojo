--!strict
local Helpers = require(script.Parent.Parent.Helpers)
local DialogTree = require(script.Parent.Parent.Parent.Core.DialogTree)

type DialogNode = DialogTree.DialogNode
type DialogChoice = DialogTree.DialogChoice

local SimpleChoiceGenerator = {}

function SimpleChoiceGenerator.Generate(Choice: DialogChoice, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = ""

	Code = Code .. Indent .. "{\n"
	Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.Text) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseNode = {\n"
		Code = Code .. Indent .. "\t\tText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"

		if Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
			Code = Code .. Indent .. "\t\tChoices = {\n"
			for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
				Code = Code .. SimpleChoiceGenerator.GenerateNested(SubChoice, Depth + 2)
			end
			Code = Code .. Indent .. "\t}\\n"
		end

		Code = Code .. Indent .. "\t},\n"
	end

	Code = Code .. Indent .. "},\n"

	return Code
end

function SimpleChoiceGenerator.GenerateNested(Choice: DialogChoice, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = ""

	Code = Code .. Indent .. "{\n"
	Code = Code .. Indent .. "\tText = \"" .. Helpers.EscapeString(Choice.Text) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseNode = {\n"
		Code = Code .. Indent .. "\t\tText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"

		if Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
			Code = Code .. Indent .. "\t\tChoices = {\n"
			for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
				Code = Code .. SimpleChoiceGenerator.GenerateNested(SubChoice, Depth + 2)
			end
			Code = Code .. Indent .. "\t}\\n"
		end

		Code = Code .. Indent .. "\t},\n"
	end

	Code = Code .. Indent .. "},\n"

	return Code
end

return SimpleChoiceGenerator