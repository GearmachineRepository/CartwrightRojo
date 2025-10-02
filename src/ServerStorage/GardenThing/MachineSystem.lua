-- Module that handles farm machines like sprinklers, fertilizers, etc.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local PlantGrower = require(script.Parent:WaitForChild("PlantGrower")) -- Adjust path as needed

local MachineSystem = {}

-- Active machine connections storage (since we can't store them in attributes)
local ActiveConnections = {}

-- Machine configurations
MachineSystem.MachineTypes = {
	Sprinkler = {
		waterConsumption = 1, -- Water units per second
		effectRadius = 20, -- Studs
		rotationSpeed = 180, -- Degrees per second
		plantModifier = "Sprinkler", -- Growth modifier to apply
		particleNames = {"WaterSpray", "Mist"}, -- Particle effect names to look for
		requiresWater = true,
		description = "Waters nearby plants to increase growth speed"
	},

	Fertilizer = {
		waterConsumption = 0, -- No water needed
		effectRadius = 15,
		rotationSpeed = 0, -- No rotation
		plantModifier = "Fertilizer",
		particleNames = {"FertilizerDust", "Particles"},
		requiresWater = false,
		description = "Fertilizes nearby plants for enhanced growth"
	},

	Greenhouse = {
		waterConsumption = 0,
		effectRadius = 30,
		rotationSpeed = 0,
		plantModifier = "Greenhouse",
		particleNames = {"Humidity", "Steam"},
		requiresWater = false,
		description = "Provides protected environment for plants"
	}
}

-- Construct and initialize a machine
function MachineSystem:Construct(MachineModel, MachineType)
	local MachineData = self.MachineTypes[MachineType]
	if not MachineData then
		warn("Invalid machine type: " .. tostring(MachineType))
		return false
	end

	-- Store machine configuration
	MachineModel:SetAttribute("MachineType", MachineType)
	MachineModel:SetAttribute("WaterLevel", 100) -- Start with full water
	MachineModel:SetAttribute("IsOperating", false)
	-- Note: We'll track affected plants using a different method since arrays aren't supported

	-- Find the rotator model if it exists
	local Rotator = MachineModel:FindFirstChild("Rotator")
	if Rotator and Rotator:IsA("Model") and Rotator.PrimaryPart then
		MachineModel:SetAttribute("HasRotator", true)
		-- Store original rotation for reference
		Rotator.PrimaryPart:SetAttribute("OriginalCFrame", Rotator.PrimaryPart.CFrame)
	else
		MachineModel:SetAttribute("HasRotator", false)
	end

	-- Initialize particle effects
	self:InitializeParticleEffects(MachineModel)
	
	return true
end

-- Initialize particle effects in the machine
function MachineSystem:InitializeParticleEffects(MachineModel)
	local MachineType = MachineModel:GetAttribute("MachineType")
	local MachineData = self.MachineTypes[MachineType]

	if not MachineData then return end

	-- Find and store all particle effects
	local ParticleEffects = {}

	for _, Descendant in pairs(MachineModel:GetDescendants()) do
		if Descendant:IsA("ParticleEmitter") then
			-- Check if this particle matches our expected names
			for _, ParticleName in pairs(MachineData.particleNames) do
				if string.find(Descendant.Name:lower(), ParticleName:lower()) then
					table.insert(ParticleEffects, Descendant)
					Descendant.Enabled = false -- Start disabled
					break
				end
			end
		end
	end
end

-- Start machine operation
function MachineSystem:StartMachine(MachineModel)
	local MachineType = MachineModel:GetAttribute("MachineType")
	local MachineData = self.MachineTypes[MachineType]

	if not MachineData then
		warn("Machine not properly constructed")
		return false
	end

	-- Check water requirements
	if MachineData.requiresWater then
		local WaterLevel = MachineModel:GetAttribute("WaterLevel") or 0
		if WaterLevel <= 0 then
			warn("Machine out of water!")
			return false
		end
	end

	-- Mark as operating
	MachineModel:SetAttribute("IsOperating", true)

	-- Start particle effects
	self:ToggleParticleEffects(MachineModel, true)

	-- Start rotation if applicable
	if MachineModel:GetAttribute("HasRotator") and MachineData.rotationSpeed > 0 then
		self:StartRotation(MachineModel)
	end

	-- Helper function to sanitize names for attributes (remove spaces and special characters)
	function MachineSystem:SanitizeName(Name)
		-- Replace spaces and special characters with underscores
		return string.gsub(Name, "[%s%p]", "_")
	end

	-- Start affecting nearby plants
	self:StartPlantEffects(MachineModel)
	
	local HasAudio = MachineModel:FindFirstChild("ActiveSound", true)
	if HasAudio then
		HasAudio:Play()
	end

	-- Start water consumption if applicable
	if MachineData.requiresWater then
		self:StartWaterConsumption(MachineModel)
	end
	return true
end

-- Stop machine operation
function MachineSystem:StopMachine(MachineModel)
	local MachineType = MachineModel:GetAttribute("MachineType")

	-- Mark as not operating
	MachineModel:SetAttribute("IsOperating", false)

	-- Stop particle effects
	self:ToggleParticleEffects(MachineModel, false)

	-- Stop rotation
	self:StopRotation(MachineModel)

	-- Remove plant effects
	self:StopPlantEffects(MachineModel)

	-- Stop water consumption
	self:StopWaterConsumption(MachineModel)
	
	local HasAudio = MachineModel:FindFirstChild("ActiveSound", true)
	if HasAudio then
		HasAudio:Stop()
	end

	--print("Stopped", MachineType, "machine")
end

-- Toggle particle effects on/off
function MachineSystem:ToggleParticleEffects(MachineModel, Enable)
	local MachineType = MachineModel:GetAttribute("MachineType")
	local MachineData = self.MachineTypes[MachineType]

	if not MachineData then return end

	-- Find and toggle all relevant particle effects
	for _, Descendant in pairs(MachineModel:GetDescendants()) do
		if Descendant:IsA("ParticleEmitter") then
			for _, ParticleName in pairs(MachineData.particleNames) do
				if string.find(Descendant.Name:lower(), ParticleName:lower()) then
					Descendant.Enabled = Enable
					break
				end
			end
		end
	end
end

-- Start rotator spinning
function MachineSystem:StartRotation(MachineModel)
	local MachineType = MachineModel:GetAttribute("MachineType")
	local MachineData = self.MachineTypes[MachineType]
	local Rotator = MachineModel:FindFirstChild("Rotator")

	if not Rotator or not Rotator.PrimaryPart or MachineData.rotationSpeed == 0 then
		return
	end

	local RotationConnection = RunService.Heartbeat:Connect(function(DeltaTime)
		-- Only rotate if machine is still operating
		if not MachineModel:GetAttribute("IsOperating") then
			return
		end
		-- Calculate rotation amount
		local RotationAmount = math.rad(MachineData.rotationSpeed * DeltaTime)
		-- Apply rotation around Y-axis (up)
		local CurrentCFrame = Rotator.PrimaryPart.CFrame
		Rotator:SetPrimaryPartCFrame(CurrentCFrame * CFrame.Angles(0, RotationAmount, 0))
	end)

	-- Store connection reference in our external table (NOT in attributes)
	if not ActiveConnections[MachineModel] then
		ActiveConnections[MachineModel] = {}
	end
	ActiveConnections[MachineModel].RotationConnection = RotationConnection
end

-- Stop rotator spinning
function MachineSystem:StopRotation(MachineModel)
	local RotationConnection = MachineModel:GetAttribute("RotationConnection")
	if RotationConnection then
		RotationConnection:Disconnect()
		MachineModel:SetAttribute("RotationConnection", nil)
	end
end

-- Start affecting nearby plants
function MachineSystem:StartPlantEffects(MachineModel)
	local MachineType = MachineModel:GetAttribute("MachineType")
	local MachineData = self.MachineTypes[MachineType]

	if not MachineData then return end

	local EffectConnection = RunService.Heartbeat:Connect(function()
		-- Only affect plants if machine is operating
		if not MachineModel:GetAttribute("IsOperating") then
			return
		end

		-- Reset filter each frame
		local TargetFilter = {}

		-- Find nearby plants
		local MachinePosition = MachineModel:GetPivot().Position
		local NearbyPlants = self:FindNearbyPlants(MachinePosition, MachineData.effectRadius)

		-- Apply effects to nearby plants and track them
		for _, Plant in pairs(NearbyPlants) do
			if TargetFilter[Plant] then continue end
			TargetFilter[Plant] = true
			PlantGrower:AddGrowthModifier(Plant, MachineData.plantModifier)
			-- Mark this plant as affected by this machine (sanitize the name)
			local SafeMachineName = self:SanitizeName(MachineModel.Name)
			Plant:SetAttribute("AffectedBy_" .. SafeMachineName, true)
		end

		-- Remove effects from plants that are now too far
		self:RemoveEffectsFromDistantPlants(MachineModel, MachinePosition, MachineData.effectRadius, MachineData.plantModifier)
	end)

	-- Store connection reference in our external table
	if not ActiveConnections[MachineModel] then
		ActiveConnections[MachineModel] = {}
	end
	ActiveConnections[MachineModel].PlantEffectConnection = EffectConnection
end

-- Stop affecting plants
function MachineSystem:StopPlantEffects(MachineModel)
	if ActiveConnections[MachineModel] and ActiveConnections[MachineModel].PlantEffectConnection then
		ActiveConnections[MachineModel].PlantEffectConnection:Disconnect()
		ActiveConnections[MachineModel].PlantEffectConnection = nil
	end

	-- Remove modifier from all affected plants
	local MachineType = MachineModel:GetAttribute("MachineType")
	local MachineData = self.MachineTypes[MachineType]
	if MachineData then
		self:RemoveModifierFromAllPlants(MachineData.plantModifier)
		-- Also remove the "affected by" markers
		self:RemoveAffectedByMarkers(MachineModel)
	end
end

function MachineSystem:StartWaterConsumption(MachineModel)
	local MachineType = MachineModel:GetAttribute("MachineType")
	local MachineData = self.MachineTypes[MachineType]

	if not MachineData or MachineData.waterConsumption == 0 then return end

	local WaterConnection = RunService.Heartbeat:Connect(function(DeltaTime)
		-- Only consume water if operating
		if not MachineModel:GetAttribute("IsOperating") then
			return
		end

		local CurrentWater = MachineModel:GetAttribute("WaterLevel") or 0
		local WaterUsed = MachineData.waterConsumption * DeltaTime
		local NewWaterLevel = math.max(0, CurrentWater - WaterUsed)

		MachineModel:SetAttribute("WaterLevel", NewWaterLevel)

		-- Stop machine if out of water
		if NewWaterLevel <= 0 then
			self:StopMachine(MachineModel)
			warn("Machine stopped: Out of water!")
		end
	end)

	-- Store connection reference in our external table
	if not ActiveConnections[MachineModel] then
		ActiveConnections[MachineModel] = {}
	end
	ActiveConnections[MachineModel].WaterConnection = WaterConnection
end

-- Stop water consumption
function MachineSystem:StopWaterConsumption(MachineModel)
	if ActiveConnections[MachineModel] and ActiveConnections[MachineModel].WaterConnection then
		ActiveConnections[MachineModel].WaterConnection:Disconnect()
		ActiveConnections[MachineModel].WaterConnection = nil
	end
end

-- Find nearby plants within radius
function MachineSystem:FindNearbyPlants(Position, Radius)
	local NearbyPlants = {}

	-- Search through workspace for plant models
	for _, Child in pairs(workspace.Plants:GetChildren()) do
		if Child:IsA("Model") and Child:GetAttribute("PlantType") then
			local PlantPosition = Child:GetPivot().Position
			local Distance = (PlantPosition - Position).Magnitude

			if Distance <= Radius then
				table.insert(NearbyPlants, Child)
			end
		end
	end

	return NearbyPlants
end

-- Remove effects from plants that are now too far away
function MachineSystem:RemoveEffectsFromDistantPlants(MachineModel, MachinePosition, Radius, ModifierName)
	-- This is a simplified version - in production you'd want to track affected plants more carefully
	for _, Child in pairs(workspace:GetChildren()) do
		if Child:IsA("Model") and Child:GetAttribute("PlantType") then
			local PlantPosition = Child:GetPivot().Position
			local Distance = (PlantPosition - MachinePosition).Magnitude

			if Distance > Radius then
				PlantGrower:RemoveGrowthModifier(Child, ModifierName)
			end
		end
	end
end

-- Remove modifier from all plants (used when machine stops)
function MachineSystem:RemoveModifierFromAllPlants(ModifierName)
	for _, Child in pairs(workspace:GetChildren()) do
		if Child:IsA("Model") and Child:GetAttribute("PlantType") then
			PlantGrower:RemoveGrowthModifier(Child, ModifierName)
		end
	end
end

-- Remove "affected by" markers from plants
function MachineSystem:RemoveAffectedByMarkers(MachineModel)
	local SafeMachineName = self:SanitizeName(MachineModel.Name)
	for _, Child in pairs(workspace:GetChildren()) do
		if Child:IsA("Model") and Child:GetAttribute("PlantType") then
			Child:SetAttribute("AffectedBy_" .. SafeMachineName, nil)
		end
	end
end

-- Add water to machine
function MachineSystem:AddWater(MachineModel, Amount)
	local CurrentWater = MachineModel:GetAttribute("WaterLevel") or 0
	local NewWaterLevel = math.min(100, CurrentWater + Amount) -- Cap at 100
	MachineModel:SetAttribute("WaterLevel", NewWaterLevel)
	
	return NewWaterLevel
end

-- Get machine status
function MachineSystem:GetMachineStatus(MachineModel)
	local MachineType = MachineModel:GetAttribute("MachineType")
	local IsOperating = MachineModel:GetAttribute("IsOperating")
	local WaterLevel = MachineModel:GetAttribute("WaterLevel")

	return {
		MachineType = MachineType,
		IsOperating = IsOperating,
		WaterLevel = WaterLevel,
		Description = self.MachineTypes[MachineType] and self.MachineTypes[MachineType].description or "Unknown machine"
	}
end

return MachineSystem