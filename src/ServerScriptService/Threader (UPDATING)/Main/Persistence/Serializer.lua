--!strict
local HttpService = game:GetService("HttpService")
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogNode = DialogTree.DialogNode

local Serializer = {}

function Serializer.Serialize(Tree: DialogNode): string
	return HttpService:JSONEncode(Tree)
end

function Serializer.Deserialize(JsonString: string): DialogNode?
	local Success, Result = pcall(function()
		return HttpService:JSONDecode(JsonString)
	end)

	if Success then
		return Result
	else
		warn("[Serializer] Failed to deserialize:", Result)
		return nil
	end
end

function Serializer.SaveToModule(Tree: DialogNode, ModuleName: string): ModuleScript?
	local JsonData = Serializer.Serialize(Tree)

	local Success, Module = pcall(function()
		local Mod = Instance.new("ModuleScript")
		Mod.Name = ModuleName .. "_Data"

		local DataValue = Instance.new("StringValue")
		DataValue.Name = "TreeData"
		DataValue.Value = JsonData
		DataValue.Parent = Mod

		return Mod
	end)

	if Success then
		return Module
	else
		warn("[Serializer] Failed to save module:", Module)
		return nil
	end
end

function Serializer.LoadFromModule(Module: ModuleScript): DialogNode?
	local DataValue = Module:FindFirstChild("TreeData")
	if DataValue and DataValue:IsA("StringValue") then
		return Serializer.Deserialize(DataValue.Value)
	end

	warn("[Serializer] No TreeData found in module")
	return nil
end

return Serializer