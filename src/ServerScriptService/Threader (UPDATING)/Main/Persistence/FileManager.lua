--!strict
local FileManager = {}

function FileManager.CreateModule(Name: string, Source: string): ModuleScript?
	local Success, Result = pcall(function()
		local Module = Instance.new("ModuleScript")
		Module.Name = Name
		Module.Source = Source
		return Module
	end)

	if Success then
		return Result
	else
		warn("[FileManager] Failed to create module:", Result)
		return nil
	end
end

function FileManager.SaveToStorage(Name: string, Data: string): boolean
	local DataStoreFolder = game:GetService("ServerStorage"):FindFirstChild("DialogTrees")
	if not DataStoreFolder then
		DataStoreFolder = Instance.new("Folder")
		DataStoreFolder.Name = "DialogTrees"
		DataStoreFolder.Parent = game:GetService("ServerStorage")
	end

	local ExistingData = DataStoreFolder:FindFirstChild(Name)
	if ExistingData then
		ExistingData:Destroy()
	end

	local Success = pcall(function()
		local DataValue = Instance.new("StringValue")
		DataValue.Name = Name
		DataValue.Value = Data
		DataValue.Parent = DataStoreFolder
	end)

	return Success
end

function FileManager.LoadFromStorage(Name: string): string?
	local DataStoreFolder = game:GetService("ServerStorage"):FindFirstChild("DialogTrees")
	if not DataStoreFolder then
		return nil
	end

	local DataValue = DataStoreFolder:FindFirstChild(Name)
	if DataValue and DataValue:IsA("StringValue") then
		return DataValue.Value
	end

	return nil
end

function FileManager.GetAllSaved(): {string}
	local Names: {string} = {}
	local DataStoreFolder = game:GetService("ServerStorage"):FindFirstChild("DialogTrees")

	if DataStoreFolder then
		for _, Child in ipairs(DataStoreFolder:GetChildren()) do
			if Child:IsA("StringValue") then
				table.insert(Names, Child.Name)
			end
		end
	end

	return Names
end

function FileManager.Delete(Name: string): boolean
	local DataStoreFolder = game:GetService("ServerStorage"):FindFirstChild("DialogTrees")
	if not DataStoreFolder then
		return false
	end

	local DataValue = DataStoreFolder:FindFirstChild(Name)
	if DataValue then
		DataValue:Destroy()
		return true
	end

	return false
end

return FileManager