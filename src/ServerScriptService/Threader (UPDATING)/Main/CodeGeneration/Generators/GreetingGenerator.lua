--!strict
local Helpers = require(script.Parent.Parent.Helpers)

local GreetingGenerator = {}

function GreetingGenerator.Generate(Tree: any): string
	if not Tree.Greetings or #Tree.Greetings == 0 then
		return "\tlocal Greeting = \"" .. Helpers.EscapeString(Tree.Text) .. "\"\n\n"
	end

	local Code = ""

	for Index, Greeting in ipairs(Tree.Greetings) do
		local VarName = Greeting.ConditionType:gsub("%s+", "") .. Index
		Code = Code .. "\tlocal " .. VarName .. " = "

		if Greeting.ConditionType == "HasQuest" then
			Code = Code .. "DialogBuilder.HasActiveQuest(Player, \"" .. Greeting.ConditionValue .. "\")\n"
		elseif Greeting.ConditionType == "CompletedQuest" then
			Code = Code .. "DialogBuilder.HasCompletedQuest(Player, \"" .. Greeting.ConditionValue .. "\")\n"
		elseif Greeting.ConditionType == "DialogFlag" then
			Code = Code .. "DialogConditions.Check(Player, {Type = \"DialogFlag\", Value = \"" .. Greeting.ConditionValue .. "\"})\n"
		else
			Code = Code .. "false\n"
		end
	end

	Code = Code .. "\n\tlocal Greeting = DialogHelpers.GetConditionalGreeting({\n"

	for Index, Greeting in ipairs(Tree.Greetings) do
		local VarName = Greeting.ConditionType:gsub("%s+", "") .. Index
		Code = Code .. "\t\t{" .. VarName .. ", \"" .. Helpers.EscapeString(Greeting.GreetingText) .. "\"},\n"
	end

	Code = Code .. "\t}, \"" .. Helpers.EscapeString(Tree.Text) .. "\")\n\n"

	return Code
end

return GreetingGenerator