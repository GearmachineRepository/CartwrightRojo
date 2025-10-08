--!strict

local Helpers = {}

function Helpers.GetIndent(Depth: number): string
	return string.rep("\t", Depth)
end

function Helpers.EscapeString(Text: string): string
	local Escaped = Text:gsub("\\", "\\\\")
	Escaped = Escaped:gsub('"', '\\"')
	Escaped = Escaped:gsub("\n", "\\n")
	Escaped = Escaped:gsub("\r", "\\r")
	Escaped = Escaped:gsub("\t", "\\t")
	return Escaped
end

function Helpers.GenerateCondition(Condition: any, Depth: number): string
	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "{Type = \"" .. Condition.Type .. "\", Value = "

	if type(Condition.Value) == "string" then
		Code = Code .. "\"" .. Helpers.EscapeString(Condition.Value) .. "\""
	elseif type(Condition.Value) == "table" then
		Code = Code .. "{"
		local First = true
		for Key, Val in pairs(Condition.Value) do
			if not First then
				Code = Code .. ", "
			end
			First = false
			if type(Val) == "string" then
				Code = Code .. Key .. " = \"" .. Helpers.EscapeString(Val) .. "\""
			else
				Code = Code .. Key .. " = " .. tostring(Val)
			end
		end
		Code = Code .. "}"
	else
		Code = Code .. tostring(Condition.Value)
	end

	Code = Code .. "},\n"
	return Code
end

function Helpers.GenerateFlagsArray(Flags: {string}): string
	if not Flags or #Flags == 0 then
		return ""
	end

	local FilteredFlags = {}
	for _, Flag in ipairs(Flags) do
		if Flag ~= "None" then
			table.insert(FilteredFlags, '"' .. Flag .. '"')
		end
	end

	if #FilteredFlags == 0 then
		return ""
	end

	return table.concat(FilteredFlags, ", ")
end

function Helpers.GenerateCommandFunction(Command: string, Depth: number): string
	if not Command or Command == "" then
		return ""
	end

	local Indent = Helpers.GetIndent(Depth)
	local Code = Indent .. "Command = function(Plr: Player)\n"
	Code = Code .. Indent .. "\t" .. Command:gsub("\n", "\n" .. Indent .. "\t") .. "\n"
	Code = Code .. Indent .. "end,\n"
	return Code
end

return Helpers