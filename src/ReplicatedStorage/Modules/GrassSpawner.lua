--!nonstrict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Terrain = workspace.Terrain

-- CONFIGURATION --
local FoliageModels = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("FoliageModels")
local GRASS_MODEL = FoliageModels:WaitForChild("GrassModel")

local REGION_CENTER = Vector3.new(0, 50, 0)
local REGION_SIZE = Vector3.new(2000, 200, 2000)
local GRID_RESOLUTION = 4

-- Noise settings
local NOISE_SCALE = 0.03
local NOISE_DETAIL_SCALE = 0.1
local NOISE_THRESHOLD = 0.15

local GRASS_DENSITY = 0.5
local RAYCAST_HEIGHT = 200

-- Materials allowed
local ALLOWED_MATERIALS = {
	[Enum.Material.Grass] = true,
	[Enum.Material.LeafyGrass] = true
}

-- Appearance variation
local RANDOM_ROTATION = true
local ALIGN_TO_NORMAL = true
local SCALE_VARIATION = .25

local MIN_GRASS_HEIGHT = 0.75
local MAX_GRASS_HEIGHT = 5.5
local HEIGHT_NOISE_SCALE = 0.1

-- Pool settings
local INITIAL_POOL_SIZE = 100
local POOL_GROWTH_SIZE = 50

-- Parent folder
local grassFolder = Instance.new("Folder")
grassFolder.Name = "Grass"
grassFolder.Parent = workspace:WaitForChild("World"):WaitForChild("Foliage")

-- Object Pool
local grassPool = {}
local activeGrass = {}
local grassSpawnData = {} -- Stores position/normal data for all possible spawn points

-- Raycast settings
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude
rayParams.FilterDescendantsInstances = {grassFolder}

local function layeredPerlin(x, z, seed)
	local base = math.noise(x * NOISE_SCALE + seed, z * NOISE_SCALE + seed)
	local detail = math.noise(x * NOISE_DETAIL_SCALE + seed + 100, z * NOISE_DETAIL_SCALE + seed + 100)
	return (base + detail * 0.5)
end

local function isAllowedMaterial(material)
	return ALLOWED_MATERIALS[material] or false
end

local function getGrassHeight(x, z, seed)
	local noise = math.noise(x * HEIGHT_NOISE_SCALE + seed, z * HEIGHT_NOISE_SCALE + seed)
	local normalized = (noise + 1) / 2
	normalized = normalized * normalized * (3 - 2 * normalized)
	local height = MIN_GRASS_HEIGHT + (MAX_GRASS_HEIGHT - MIN_GRASS_HEIGHT) * normalized
	return height
end

-- Create a new grass instance for the pool
local function createGrassInstance()
	local grass = GRASS_MODEL:Clone()
	grass.PrimaryPart.Color = workspace.Terrain:GetMaterialColor(Enum.Material.Grass)
	grass.Parent = grassFolder
	grass:AddTag("Grass")

	-- Cache parts AND their original sizes
	local parts = {}
	local originalSizes = {}
	local originalOffsets = {}

	for _, part in ipairs(grass:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
			originalSizes[part] = part.Size
			originalOffsets[part] = grass:GetPivot():PointToObjectSpace(part.Position)
		end
	end

	return {
		model = grass,
		parts = parts,
		originalSizes = originalSizes,
		originalOffsets = originalOffsets,
		active = false
	}
end

-- Initialize the pool
local function initializePool(size)
	for i = 1, size do
		local grassInstance = createGrassInstance()
		-- Start invisible
		for _, part in ipairs(grassInstance.parts) do
			part.Transparency = 1
		end
		table.insert(grassPool, grassInstance)
	end
end

-- Get a grass instance from the pool
local function getFromPool()
	-- Try to find an inactive instance
	for _, instance in ipairs(grassPool) do
		if not instance.active then
			instance.active = true
			return instance
		end
	end

	-- If none available, grow the pool
	for i = 1, POOL_GROWTH_SIZE do
		local grassInstance = createGrassInstance()
		for _, part in ipairs(grassInstance.parts) do
			part.Transparency = 1
		end
		table.insert(grassPool, grassInstance)
	end

	-- Return the first newly created instance
	local instance = grassPool[#grassPool - POOL_GROWTH_SIZE + 1]
	instance.active = true
	return instance
end

-- Return a grass instance to the pool
local function returnToPool(instance)
	instance.active = false
	-- Hide the grass
	for _, part in ipairs(instance.parts) do
		part.Transparency = 1
	end
end

-- Configure a grass instance with position, normal, and variation
local function configureGrass(instance, position, normal, noiseSeed)
	local grass = instance.model
	local pivot

	if ALIGN_TO_NORMAL and normal then
		local up = normal
		local right = up:Cross(Vector3.new(0, 0, 1))
		if right.Magnitude < 0.01 then
			right = up:Cross(Vector3.new(1, 0, 0))
		end
		local forward = right:Cross(up)
		pivot = CFrame.fromMatrix(position, right.Unit, up.Unit, forward.Unit)
	else
		pivot = CFrame.new(position)
	end

	local randomYRot = CFrame.new()
	if RANDOM_ROTATION then
		randomYRot = CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
		pivot = pivot * randomYRot
	end

	grass:PivotTo(pivot)

	-- Apply height scaling
	local height = getGrassHeight(position.X, position.Z, noiseSeed)
	local heightScale = height / GRASS_MODEL.PrimaryPart.Size.Y

	-- Apply scale variation
	local variation = 1
	if SCALE_VARIATION > 0 then
		variation = 1 + (math.random() - 0.5) * 2 * SCALE_VARIATION
	end

	for _, part in ipairs(instance.parts) do
		-- Use the ORIGINAL size, not the current size
		local originalSize = instance.originalSizes[part]
		local originalOffset = instance.originalOffsets[part]

		local newSize = Vector3.new(
			originalSize.X,
			originalSize.Y * heightScale * variation,
			originalSize.Z
		)

		part.Size = newSize

		local worldPos = grass:GetPivot():PointToWorldSpace(originalOffset * Vector3.new(1, heightScale * variation, 1))
		part.CFrame = CFrame.new(worldPos) * randomYRot

		-- Make visible
		part.Transparency = 0
	end

	return instance
end

-- Scan the region and store all valid spawn points
local function scanGrassSpawnPoints()
	local seed = math.random(0, 9999)
	local noiseSeed = math.random(1, 10000)

	local minX = REGION_CENTER.X - REGION_SIZE.X / 2
	local maxX = REGION_CENTER.X + REGION_SIZE.X / 2
	local minZ = REGION_CENTER.Z - REGION_SIZE.Z / 2
	local maxZ = REGION_CENTER.Z + REGION_SIZE.Z / 2

	local spawnPoints = {}

	for x = minX, maxX, GRID_RESOLUTION do
		for z = minZ, maxZ, GRID_RESOLUTION do
			local noiseVal = layeredPerlin(x, z, seed)
			if noiseVal > NOISE_THRESHOLD and math.random() < GRASS_DENSITY then
				local rayOrigin = Vector3.new(x, REGION_CENTER.Y + RAYCAST_HEIGHT, z)
				local rayDir = Vector3.new(0, -RAYCAST_HEIGHT * 2, 0)
				local result = workspace:Raycast(rayOrigin, rayDir, rayParams)

				if result and isAllowedMaterial(result.Material) then
					table.insert(spawnPoints, {
						position = result.Position,
						normal = result.Normal,
						noiseSeed = noiseSeed
					})
				end
			end
		end
		task.wait()
	end

	return spawnPoints
end

-- Public API for the optimizer to use
local GrassSystem = {}

function GrassSystem.Initialize()
	initializePool(INITIAL_POOL_SIZE)
	grassSpawnData = scanGrassSpawnPoints()
end

function GrassSystem.GetSpawnData()
	return grassSpawnData
end

function GrassSystem.SpawnGrassAt(index)
	local data = grassSpawnData[index]
	if not data then return nil end

	-- Check if already spawned
	if activeGrass[index] then
		return activeGrass[index]
	end

	local instance = getFromPool()
	configureGrass(instance, data.position, data.normal, data.noiseSeed)
	activeGrass[index] = instance

	return instance
end

function GrassSystem.DespawnGrassAt(index)
	local instance = activeGrass[index]
	if instance then
		returnToPool(instance)
		activeGrass[index] = nil
	end
end

function GrassSystem.GetActiveCount()
	local count = 0
	for _ in pairs(activeGrass) do
		count = count + 1
	end
	return count
end

function GrassSystem.GetPoolSize()
	return #grassPool
end

-- Initialize the system
GrassSystem.Initialize()

return GrassSystem