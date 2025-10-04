--!strict

local HttpService = game:GetService("HttpService")

local UIDManager = {}

function UIDManager.EnsureModelUID(Instance: Instance): string
	local UID = Instance:GetAttribute("UID")
	if typeof(UID) ~= "string" or #UID == 0 then
		UID = HttpService:GenerateGUID(false)
		Instance:SetAttribute("UID", UID)
	end
	return UID
end

function UIDManager.ClearModelUID(Instance: Instance): ()
	if Instance:GetAttribute("UID") then
		Instance:SetAttribute("UID", nil)
	end
end

function UIDManager.Matches(Instance: Instance, OtherUID: string): boolean
	return Instance:GetAttribute("UID") == OtherUID
end

return UIDManager