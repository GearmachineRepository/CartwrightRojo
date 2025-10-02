-- Run this in Studio to process plants and generate PlantStages code

local StudioPlantProcessor = {}

-- Configuration
local Config = {
	-- Part type detection keywords
	partTypes = {
		root = {"root", "bulb", "base"},
		stem = {"stem", "trunk", "stalk", "branch"},
		leaf = {"leaf", "leaves", "foliage"},
		flower = {"flower", "petal", "bloom", "bud", "center"},
		fruit = {"fruit", "berry", "seed", "pod", "apple", "tomato"},
		thorn = {"thorn", "spike", "needle"}
	},

	-- Growth order priority
	growthOrder = {"root", "stem", "leaf", "flower", "fruit", "thorn"},

	-- Parts per stage (adjust as needed)
	partsPerStage = 3,

	-- Minimum height difference for new stage
	heightThreshold = 1.0
}

-- Get part type from name
function StudioPlantProcessor:GetPartType(partName)
	local lowerName = partName:lower()

	for partType, keywords in pairs(Config.partTypes) do
		for _, keyword in pairs(keywords) do
			if string.find(lowerName, keyword) then
				return partType
			end
		end
	end

	return "unknown"
end

-- Rename parts systematically
function StudioPlantProcessor:RenamePlantParts(plantModel)
	local parts = {}

	-- Collect all BaseParts
	for _, descendant in pairs(plantModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	-- Sort by height (bottom to top)
	table.sort(parts, function(a, b)
		return a.Position.Y < b.Position.Y
	end)

	-- Categorize and count parts
	local partCounts = {}
	for _, partType in pairs(Config.growthOrder) do
		partCounts[partType] = 0
	end
	partCounts.unknown = 0

	-- Rename parts
	local renamedParts = {}
	for _, part in pairs(parts) do
		local partType = self:GetPartType(part.Name)
		partCounts[partType] = partCounts[partType] + 1

		local newName = string.upper(partType:sub(1,1)) .. partType:sub(2) .. "_" .. string.format("%02d", partCounts[partType])

		print("Renaming:", part.Name, "->", newName)
		part.Name = newName

		table.insert(renamedParts, {
			part = part,
			name = newName,
			type = partType,
			height = part.Position.Y
		})
	end

	return renamedParts
end

-- Generate stages based on renamed parts
function StudioPlantProcessor:GenerateStages(renamedParts)
	local stages = {}
	local stageNum = 1
	local currentStage = {}
	local lastPartType = nil
	local lastHeight = nil

	-- Group parts into stages
	for _, partData in pairs(renamedParts) do
		local shouldStartNewStage = false

		-- Start new stage if:
		-- 1. Part type changed to a later growth order
		-- 2. Current stage has enough parts
		-- 3. Significant height difference
		if lastPartType then
			local currentTypeIndex = self:GetGrowthOrderIndex(partData.type)
			local lastTypeIndex = self:GetGrowthOrderIndex(lastPartType)

			if currentTypeIndex > lastTypeIndex or
				#currentStage >= Config.partsPerStage or
				(lastHeight and partData.height - lastHeight > Config.heightThreshold) then
				shouldStartNewStage = true
			end
		end

		if shouldStartNewStage and #currentStage > 0 then
			stages["Stage" .. stageNum] = {}
			for _, stagePart in pairs(currentStage) do
				table.insert(stages["Stage" .. stageNum], stagePart)
			end
			stageNum = stageNum + 1
			currentStage = {}
		end

		table.insert(currentStage, partData.name)
		lastPartType = partData.type
		lastHeight = partData.height
	end

	-- Add final stage
	if #currentStage > 0 then
		stages["Stage" .. stageNum] = {}
		for _, stagePart in pairs(currentStage) do
			table.insert(stages["Stage" .. stageNum], stagePart)
		end
	end

	return stages
end

-- Get growth order index for a part type
function StudioPlantProcessor:GetGrowthOrderIndex(partType)
	for i, orderType in pairs(Config.growthOrder) do
		if orderType == partType then
			return i
		end
	end
	return 999 -- Unknown types go last
end

-- Generate the Lua table code for PlantStages
function StudioPlantProcessor:GenerateStagesCode(plantName, stages)
	local code = {}

	table.insert(code, '["' .. plantName .. '"] = {')

	-- Sort stage names
	local stageNames = {}
	for stageName, _ in pairs(stages) do
		table.insert(stageNames, stageName)
	end
	table.sort(stageNames, function(a, b)
		local numA = tonumber(string.match(a, "%d+"))
		local numB = tonumber(string.match(b, "%d+"))
		return (numA or 0) < (numB or 0)
	end)

	-- Generate stage code
	for _, stageName in pairs(stageNames) do
		local parts = stages[stageName]
		local partsList = {}
		for _, partName in pairs(parts) do
			table.insert(partsList, '"' .. partName .. '"')
		end
		table.insert(code, '\t' .. stageName .. ' = {' .. table.concat(partsList, ', ') .. '},')
	end

	table.insert(code, '},')

	return table.concat(code, '\n')
end

-- Generate config code for PlantStages
function StudioPlantProcessor:GenerateConfigCode(plantName, customConfig)
	customConfig = customConfig or {}

	local defaultConfig = {
		totalBloomTime = 15,
		easingStyle = "Enum.EasingStyle.Quad",
		easingDirection = "Enum.EasingDirection.Out",
		growthMode = "directional",
		timingMode = "dynamic",
		smoothness = "smooth"
	}

	-- Merge with custom config
	for key, value in pairs(customConfig) do
		defaultConfig[key] = value
	end

	local code = {}
	table.insert(code, '["' .. plantName .. '"] = {')

	for key, value in pairs(defaultConfig) do
		if type(value) == "string" and not string.find(value, "Enum") then
			table.insert(code, '\t' .. key .. ' = "' .. value .. '",')
		elseif type(value) == "number" then
			table.insert(code, '\t' .. key .. ' = ' .. value .. ',')
		else
			table.insert(code, '\t' .. key .. ' = ' .. tostring(value) .. ',')
		end
	end

	table.insert(code, '},')

	return table.concat(code, '\n')
end

-- Main processing function
function StudioPlantProcessor:ProcessPlant(plantModel, plantName, customConfig)

	print("PROCESSING PLANT:", plantName)


	-- Step 1: Rename parts
	print("\n1. Renaming parts...")
	local renamedParts = self:RenamePlantParts(plantModel)

	-- Step 2: Generate stages
	print("\n2. Generating stages...")
	local stages = self:GenerateStages(renamedParts)

	-- Step 3: Print results
	print("\n3. Generated stages:")
	for stageName, parts in pairs(stages) do
		print(stageName .. ":", table.concat(parts, ", "))
	end

	-- Step 4: Generate code
	print("\n4. CODE TO ADD TO PlantStages.Plants:")
	print(self:GenerateStagesCode(plantName, stages))

	print("\n5. CODE TO ADD TO PlantStages.Config:")
	print(self:GenerateConfigCode(plantName, customConfig))

	print("PROCESSING COMPLETE FOR:", plantName)


	return {
		stages = stages,
		renamedParts = renamedParts
	}
end

-- Process all plants in a folder
function StudioPlantProcessor:ProcessAllPlantsInFolder(folder)
	print("PROCESSING ALL PLANTS IN:", folder.Name)
	print("="*60)

	local allStagesCode = {}
	local allConfigCode = {}

	for _, child in pairs(folder:GetChildren()) do
		if child:IsA("Model") then
			local result = self:ProcessPlant(child, child.Name)

			table.insert(allStagesCode, self:GenerateStagesCode(child.Name, result.stages))
			table.insert(allConfigCode, self:GenerateConfigCode(child.Name))
		end
	end

	print("\n" .. "="*60)
	print("ALL PLANTS STAGES CODE:")
	print("="*60)
	print(table.concat(allStagesCode, '\n'))

	print("\n" .. "="*60)
	print("ALL PLANTS CONFIG CODE:")
	print("="*60)
	print(table.concat(allConfigCode, '\n'))
end

-- Quick setup function
function StudioPlantProcessor:QuickProcess(plantModelOrFolder)
	if plantModelOrFolder:IsA("Model") then
		self:ProcessPlant(plantModelOrFolder, plantModelOrFolder.Name)
	elseif plantModelOrFolder:IsA("Folder") then
		self:ProcessAllPlantsInFolder(plantModelOrFolder)
	else
		warn("Please provide a Model or Folder")
	end
end

return StudioPlantProcessor

--[[
USAGE EXAMPLES:

-- Process a single plant
local processor = require(script.StudioPlantProcessor)
local myPlant = workspace.Plants.TomatoPlant
processor:ProcessPlant(myPlant, "TomatoPlant")

-- Process all plants in a folder
local plantsFolder = workspace.Plants
processor:ProcessAllPlantsInFolder(plantsFolder)

-- Quick process (auto-detects Model vs Folder)
processor:QuickProcess(workspace.Plants.Rose)
processor:QuickProcess(workspace.Plants) -- whole folder

-- Process with custom config
processor:ProcessPlant(myPlant, "TomatoPlant", {
    totalBloomTime = 25,
    smoothness = "chunky"
})
--]]