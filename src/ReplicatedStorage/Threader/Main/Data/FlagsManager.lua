--!strict
local FlagsManager = {}

local RegisteredFlags: {string} = {}

function FlagsManager.GetAllFlags(): {string}
	return RegisteredFlags
end

function FlagsManager.AddFlag(FlagName: string)
	if not table.find(RegisteredFlags, FlagName) then
		table.insert(RegisteredFlags, FlagName)
		table.sort(RegisteredFlags)
	end
end

function FlagsManager.RemoveFlag(FlagName: string)
	local Index = table.find(RegisteredFlags, FlagName)
	if Index then
		table.remove(RegisteredFlags, Index)
	end
end

function FlagsManager.HasFlag(FlagName: string): boolean
	return table.find(RegisteredFlags, FlagName) ~= nil
end

return FlagsManager