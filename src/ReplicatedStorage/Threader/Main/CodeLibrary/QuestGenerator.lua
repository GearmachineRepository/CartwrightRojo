--!strict
local Helpers = require(script.Parent.Helpers)

local QuestGenerator = {}

function QuestGenerator.GenerateTurnIn(Choice: any, Depth: number): string
	if not Choice.QuestTurnIn then
		return ""
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "if DialogBuilder.CanTurnInQuest(Player, \"" .. Choice.QuestTurnIn.QuestId .. "\") then\n"
	Code = Code .. Indent .. "\ttable.insert(Choices, 1, {\n"
	Code = Code .. Indent .. "\t\tText = \"[QUEST] " .. Helpers.EscapeString(Choice.ButtonText) .. "\",\n"
	Code = Code .. Indent .. "\t\tResponse = {\n"
	Code = Code .. Indent .. "\t\t\tId = \"turn_in_" .. Choice.QuestTurnIn.QuestId .. "\",\n"
	Code = Code .. Indent .. "\t\t\tText = \"" .. Helpers.EscapeString(Choice.QuestTurnIn.ResponseText) .. "\",\n"
	Code = Code .. Indent .. "\t\t\tTurnInQuest = \"" .. Choice.QuestTurnIn.QuestId .. "\"\n"
	Code = Code .. Indent .. "\t\t}\n"
	Code = Code .. Indent .. "\t})\n"
	Code = Code .. Indent .. "end\n\n"
	return Code
end

return QuestGenerator