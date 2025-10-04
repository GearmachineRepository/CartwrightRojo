--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Maid = require(Modules:WaitForChild("Maid"))

local InteractionFunctions = {}

local InteractionModules = script.Parent:WaitForChild("InteractionModules")

type MaidType = typeof(Maid.new())

local LoadedModules: {[string]: any} = {}
local CacheMaid: MaidType = Maid.new()

local function LoadInteractionModule(ObjectType: string): any?
	if LoadedModules[ObjectType] then
		return LoadedModules[ObjectType]
	end

	local ModuleScript = InteractionModules:FindFirstChild(ObjectType)
	if not ModuleScript then
		warn("No interaction module found for object type: " .. ObjectType)
		return nil
	end

	local Success, Module = pcall(require, ModuleScript)
	if not Success then
		warn("Failed to load interaction module for " .. ObjectType .. ": " .. tostring(Module))
		return nil
	end

	LoadedModules[ObjectType] = Module
	return Module
end

function InteractionFunctions.ExecuteInteraction(Player: Player, Object: Instance, ObjectType: string, FunctionName: string, Config: any): ()
	local InteractionModule = LoadInteractionModule(ObjectType)

	if not InteractionModule then
		return
	end

	local InteractionFunction = InteractionModule[FunctionName]
	if not InteractionFunction then
		warn("Function " .. FunctionName .. " not found for object type: " .. ObjectType)
		return
	end

	local Success, Error = pcall(InteractionFunction, Player, Object, Config)
	if not Success then
		warn("Error executing " .. FunctionName .. " for " .. ObjectType .. ": " .. tostring(Error))
	end
end

function InteractionFunctions.ClearCache(): ()
	CacheMaid:DoCleaning()
	LoadedModules = {}
end

function InteractionFunctions.GetAvailableTypes(): {string}
	local Types = {}
	for _, Child in pairs(InteractionModules:GetChildren()) do
		if Child:IsA("ModuleScript") then
			table.insert(Types, Child.Name)
		end
	end
	return Types
end

return InteractionFunctions