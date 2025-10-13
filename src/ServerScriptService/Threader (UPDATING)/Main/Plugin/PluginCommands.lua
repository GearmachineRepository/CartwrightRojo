--!strict
local Serializer = require(script.Parent.Parent.Persistence.Serializer)
local FileManager = require(script.Parent.Parent.Persistence.FileManager)
local CodeGenerator = require(script.Parent.Parent.CodeGeneration.CodeGenerator)
local Validation = require(script.Parent.Parent.Core.Validation)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

local PluginCommands = {}

function PluginCommands.NewTree(OnComplete: (any) -> ())
	local NewTree = DialogTree.CreateNode("start", "Enter greeting text here...")
	OnComplete(NewTree)
end

function PluginCommands.SaveTree(Tree: any, Filename: string): boolean
	local ValidationResult = Validation.ValidateTree(Tree)
	if not ValidationResult.IsValid then
		warn("[PluginCommands] Tree validation failed:")
		for _, Error in ipairs(ValidationResult.Errors) do
			warn(" - " .. Error)
		end
		return false
	end

	local JsonData = Serializer.Serialize(Tree)
	if not JsonData then
		warn("[PluginCommands] Failed to serialize tree")
		return false
	end

	local Success = FileManager.SaveToStorage(Filename, JsonData)
	if Success then
		print("[PluginCommands] Saved tree:", Filename)
	end

	return Success
end

function PluginCommands.LoadTree(Filename: string): any?
	local JsonData = FileManager.LoadFromStorage(Filename)
	if not JsonData then
		warn("[PluginCommands] No data found for:", Filename)
		return nil
	end

	local Tree = Serializer.Deserialize(JsonData)
	if Tree then
		print("[PluginCommands] Loaded tree:", Filename)
	end

	return Tree
end

function PluginCommands.GenerateCode(Tree: any, Filename: string): ModuleScript?
	local ValidationResult = Validation.ValidateTree(Tree)
	if not ValidationResult.IsValid then
		warn("[PluginCommands] Cannot generate code - tree validation failed")
		return nil
	end

	local Code = CodeGenerator.Generate(Tree)
	local Module = FileManager.CreateModule(Filename, Code)

	if Module then
		local DialogsFolder = game:GetService("ReplicatedStorage"):FindFirstChild("Dialogs")
		if not DialogsFolder then
			DialogsFolder = Instance.new("Folder")
			DialogsFolder.Name = "Dialogs"
			DialogsFolder.Parent = game:GetService("ReplicatedStorage")
		end

		Module.Parent = DialogsFolder
		print("[PluginCommands] Generated code for:", Filename)
	end

	return Module
end

function PluginCommands.GetAllSavedTrees(): {string}
	return FileManager.GetAllSaved()
end

function PluginCommands.DeleteTree(Filename: string): boolean
	return FileManager.Delete(Filename)
end

return PluginCommands