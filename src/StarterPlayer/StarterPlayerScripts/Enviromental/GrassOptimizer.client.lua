--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RUN_INTERVAL = 0.05
local BASE_CULL_DISTANCE = 150
local BASE_UNCULL_DISTANCE = 130

local CULL_DISTANCE = 0
local UNCULL_DISTANCE = 0

local UserGameSettings = UserSettings():GetService("UserGameSettings")

-- Scale distances with quality level
local function updateCullDistances()
	local graphicsQuality = math.clamp(UserGameSettings.SavedQualityLevel.Value, 1, 10)
	local scale = graphicsQuality / 10
	CULL_DISTANCE = BASE_CULL_DISTANCE + (scale * 100)
	UNCULL_DISTANCE = BASE_UNCULL_DISTANCE + (scale * 80)
end
updateCullDistances()

task.spawn(function() while task.wait(2) do updateCullDistances() end end)

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Wait for the grass system to initialize
local Modules = ReplicatedStorage:WaitForChild("Modules")
local GrassSystem = require(Modules:WaitForChild("GrassSpawner")) -- Adjust path as needed

local spawnData = GrassSystem.GetSpawnData()

-- Track visibility state
local grassVisibility = {}
for i = 1, #spawnData do
	grassVisibility[i] = false
end

-- Staggered culling loop
task.spawn(function()
	local root: BasePart? = character:FindFirstChild("HumanoidRootPart")
	local currentIndex = 1

	while true do
		if not root or not root.Parent then
			character = player.Character or player.CharacterAdded:Wait()
			root = character:FindFirstChild("HumanoidRootPart")
			task.wait(RUN_INTERVAL)
			continue
		end

		local pos = root.Position
		local batchSize = math.max(50, #spawnData // 10) -- Process 10% per frame, minimum 50

		local processed = 0
		while processed < batchSize and currentIndex <= #spawnData do
			local data = spawnData[currentIndex]
			local dist = (pos - data.position).Magnitude

			if dist < UNCULL_DISTANCE and not grassVisibility[currentIndex] then
				-- Spawn grass
				GrassSystem.SpawnGrassAt(currentIndex)
				grassVisibility[currentIndex] = true
			elseif dist > CULL_DISTANCE and grassVisibility[currentIndex] then
				-- Despawn grass
				GrassSystem.DespawnGrassAt(currentIndex)
				grassVisibility[currentIndex] = false
			end

			currentIndex += 1
			processed += 1
		end

		-- Loop back to start
		if currentIndex > #spawnData then
			currentIndex = 1
		end

		task.wait(RUN_INTERVAL)
	end
end)

-- Debug info
--task.spawn(function()
--	while task.wait(5) do
--		print(string.format("Grass Stats - Active: %d/%d, Pool Size: %d", 
--			GrassSystem.GetActiveCount(), 
--			#spawnData,
--			GrassSystem.GetPoolSize()
--			))
--	end
--end)