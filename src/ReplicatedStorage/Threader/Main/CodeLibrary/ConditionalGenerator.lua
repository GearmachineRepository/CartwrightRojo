--!strict
local Helpers = require(script.Parent.Helpers)

local ConditionalGenerator = {}

function ConditionalGenerator.Generate(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	if not Choice.Conditions then
		return ""
	end

	local IsSingleCondition = #Choice.Conditions == 1
	local ConditionType = IsSingleCondition and Choice.Conditions[1].Type or nil

	if ConditionType == "DialogFlag" then
		return ConditionalGenerator.GenerateFlagGated(Choice, Depth, GenerateRecursive)
	elseif ConditionType == "HasQuest" or ConditionType == "CompletedQuest" or ConditionType == "CanTurnInQuest" then
		return ConditionalGenerator.GenerateQuestGated(Choice, Depth, GenerateRecursive)
	elseif ConditionType == "HasReputation" then
		return ConditionalGenerator.GenerateReputationGated(Choice, Depth, GenerateRecursive)
	end

	return ConditionalGenerator.GenerateGeneric(Choice, Depth, GenerateRecursive)
end

function ConditionalGenerator.GenerateNested(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	if not Choice.Conditions then
		return ""
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "DialogHelpers.Advanced.CreateConditionalChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
	end

	Code = Code .. Indent .. "\tConditions = {\n"
	for _, Condition in ipairs(Choice.Conditions) do
		Code = Code .. Helpers.GenerateCondition(Condition, Depth + 2)
	end
	Code = Code .. Indent .. "\t},\n"

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.ResponseNode and Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. Helpers.GenerateFlagsArray(Choice.ResponseNode.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Helpers.GenerateCommandFunction(Choice.Command, Depth + 1)
	end

	Code = Code .. Indent .. "}),\n\n"
	return Code
end

function ConditionalGenerator.GenerateGeneric(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateConditionalChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
	end

	Code = Code .. Indent .. "\tConditions = {\n"
	for _, Condition in ipairs(Choice.Conditions) do
		Code = Code .. Helpers.GenerateCondition(Condition, Depth + 2)
	end
	Code = Code .. Indent .. "\t},\n"

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.ResponseNode and Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. Helpers.GenerateFlagsArray(Choice.ResponseNode.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Helpers.GenerateCommandFunction(Choice.Command, Depth + 1)
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function ConditionalGenerator.GenerateFlagGated(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	local Indent = Helpers.GetIndent(Depth)
	local FlagName = Choice.Conditions[1].Value

	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateFlagGatedChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
	end

	Code = Code .. Indent .. "\tRequiredFlag = \"" .. FlagName .. "\",\n"

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.ResponseNode and Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. Helpers.GenerateFlagsArray(Choice.ResponseNode.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Helpers.GenerateCommandFunction(Choice.Command, Depth + 1)
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function ConditionalGenerator.GenerateQuestGated(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	local Indent = Helpers.GetIndent(Depth)
	local Condition = Choice.Conditions[1]
	local QuestId = Condition.Value

	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateQuestGatedChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
	end

	Code = Code .. Indent .. "\tRequiredQuest = \"" .. QuestId .. "\",\n"

	if Condition.Type == "HasQuest" then
		Code = Code .. Indent .. "\tMustBeActive = true,\n"
	elseif Condition.Type == "CanTurnInQuest" then
		Code = Code .. Indent .. "\tCanTurnIn = true,\n"
	end

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.ResponseNode and Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. Helpers.GenerateFlagsArray(Choice.ResponseNode.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Helpers.GenerateCommandFunction(Choice.Command, Depth + 1)
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

function ConditionalGenerator.GenerateReputationGated(Choice: any, Depth: number, GenerateRecursive: (any, number) -> string): string
	local Indent = Helpers.GetIndent(Depth)
	local RepData = Choice.Conditions[1].Value

	local Code = Indent .. "table.insert(Choices, DialogHelpers.Advanced.CreateReputationGatedChoice({\n"
	Code = Code .. Indent .. "\tButtonText = \"" .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"

	if Choice.ResponseNode then
		Code = Code .. Indent .. "\tResponseText = \"" .. Helpers.EscapeString(Choice.ResponseNode.Text) .. "\",\n"
	end

	if type(RepData) == "table" then
		Code = Code .. Indent .. "\tFaction = \"" .. RepData.Faction .. "\",\n"
		Code = Code .. Indent .. "\tMinRep = " .. tostring(RepData.Min) .. ",\n"
	else
		local Parts = string.split(tostring(RepData), "/")
		if #Parts == 2 then
			Code = Code .. Indent .. "\tFaction = \"" .. Parts[1] .. "\",\n"
			Code = Code .. Indent .. "\tMinRep = " .. Parts[2] .. ",\n"
		end
	end

	if Choice.ResponseNode and Choice.ResponseNode.Choices and #Choice.ResponseNode.Choices > 0 then
		Code = Code .. Indent .. "\tSubChoices = {\n"
		for _, SubChoice in ipairs(Choice.ResponseNode.Choices) do
			Code = Code .. GenerateRecursive(SubChoice, Depth + 2)
		end
		Code = Code .. Indent .. "\t},\n"
	end

	if Choice.ResponseNode and Choice.ResponseNode.SetFlags and #Choice.ResponseNode.SetFlags > 0 then
		Code = Code .. Indent .. "\tSetFlags = {" .. Helpers.GenerateFlagsArray(Choice.ResponseNode.SetFlags) .. "},\n"
	end

	if Choice.Command and Choice.Command ~= "" then
		Code = Code .. Helpers.GenerateCommandFunction(Choice.Command, Depth + 1)
	end

	Code = Code .. Indent .. "}))\n\n"
	return Code
end

return ConditionalGenerator