-- PlantGrower.lua
-- Module that handles the incremental growing of plant parts

local PlantStages = require(script.Parent:WaitForChild("PlantStages")) -- Adjust path as needed

local PlantGrower = {}

-- RNG Helper function to pick from weighted table with min/max ranges
function PlantGrower:PickFromWeightedTable(WeightedTable, BonusChance)
	BonusChance = BonusChance or 0

	-- Create working table with modified weights
	local WorkingTable = {}
	local TotalWeight = 0

	for i, Entry in pairs(WeightedTable) do
		local ModifiedWeight = Entry.weight

		-- Apply bonus to larger sizes (second half of table)
		if BonusChance > 0 and i > (#WeightedTable / 2) then
			ModifiedWeight = ModifiedWeight + (BonusChance * (#WeightedTable - i + 1))
		end

		TotalWeight = TotalWeight + ModifiedWeight

		table.insert(WorkingTable, {
			min = Entry.min,
			max = Entry.max,
			name = Entry.name,
			value = Entry.value,
			weight = ModifiedWeight,
			cumulativeWeight = TotalWeight
		})
	end

	-- Pick random value
	local RandomValue = math.random() * TotalWeight

	-- Find which entry the random value falls into
	for _, Entry in pairs(WorkingTable) do
		if RandomValue <= Entry.cumulativeWeight then
			local FinalSize = Entry.min + (math.random() * (Entry.max - Entry.min))
			return {
				size = FinalSize,
				name = Entry.name,
				value = Entry.value
			}
		end
	end

	-- Fallback (shouldn't happen)
	local FirstEntry = WorkingTable[1]
	local FallbackSize = FirstEntry.min + (math.random() * (FirstEntry.max - FirstEntry.min))
	return {
		size = FallbackSize,
		name = FirstEntry.name,
		value = FirstEntry.value
	}
end

-- Apply RNG size variation to plant by scaling target sizes
function PlantGrower:ApplyPlantSizeRNG(PlantModel, PlantType)
	local Config = PlantStages:GetPlantConfig(PlantType)
	if not Config.sizeRNG or not Config.sizeRNG.enabled then
		return "Normal", 1.0
	end
	
	local TotalBonus = 0
	for AttributeName, Value in pairs(PlantModel:GetAttributes()) do
		if string.sub(AttributeName, 1, 9) == "Modifier_" and Value then
			local ModifierName = string.sub(AttributeName, 10)
			local Bonus = Config.sizeRNG.modifierBonus[ModifierName]
			if Bonus then
				TotalBonus = TotalBonus + Bonus
			end
		end
	end

	-- Pick size using weighted RNG with min/max ranges
	local SizeResult = self:PickFromWeightedTable(Config.sizeRNG.baseChances, TotalBonus)

	-- Store plant size info
	PlantModel:SetAttribute("PlantSizeMultiplier", SizeResult.size)
	PlantModel:SetAttribute("PlantSizeName", SizeResult.name)

	-- Apply scaling to all non-fruit parts immediately
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") and Child:GetAttribute("TargetSize") then
			-- Don't scale fruit parts - they have their own RNG
			if not string.match(Child.Name, "Fruit_%d+") then
				local OriginalTarget = Child:GetAttribute("TargetSize")
				Child:SetAttribute("TargetSize", OriginalTarget * SizeResult.size)
			end
		end
	end

	return SizeResult.name, SizeResult.size
end

-- Apply RNG to individual fruits
function PlantGrower:ApplyFruitRNG(FruitPart, PlantType)
	local Config = PlantStages:GetPlantConfig(PlantType)
	if not Config.fruitSystem or not Config.fruitSystem.enabled then
		return "Normal", 1.0, 10
	end

	local FruitResult = self:PickFromWeightedTable(Config.fruitSystem.fruitRNG, 0)

	-- Apply size to this specific fruit
	local OriginalTarget = FruitPart:GetAttribute("TargetSize")
	local NewTarget = OriginalTarget * FruitResult.size
	FruitPart:SetAttribute("TargetSize", NewTarget)

	-- Store fruit info
	FruitPart:SetAttribute("FruitSizeName", FruitResult.name)
	FruitPart:SetAttribute("FruitValue", FruitResult.value)
	FruitPart:SetAttribute("FruitSizeMultiplier", FruitResult.size)

	-- Set individual fruit regrowth count
	local FruitConfig = Config.fruitSystem.fruitConfigs[FruitPart.Name]
	if FruitConfig then
		FruitPart:SetAttribute("RegrowthsRemaining", FruitConfig.maxRegrowths)
	end

	return FruitResult.name, FruitResult.size, FruitResult.value
end

-- Initialize a plant for growth by setting initial sizes and storing target sizes
function PlantGrower:InitializePlant(PlantModel, PlantType)
	if not PlantStages:IsValidPlantType(PlantType) then
		warn("Invalid plant type: " .. tostring(PlantType))
		return false
	end
	
	-- Apply plant-wide size RNG (will be applied after growth completes)
	local SizeName, SizeMultiplier = self:ApplyPlantSizeRNG(PlantModel, PlantType)
	-- Apply plant-wide scaling using Model:ScaleTo() after growth completes
	local SizeMultiplier = PlantModel:GetAttribute("PlantSizeMultiplier")
	if SizeMultiplier and SizeMultiplier ~= 1.0 then
		PlantModel:ScaleTo(SizeMultiplier)
	end
	
	-- Store original sizes as target sizes and set initial size to zero
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") then
			-- Store the original size as the target size
			Child:SetAttribute("TargetSize", Child.Size)
			-- Store the original CFrame for growth reference
			Child:SetAttribute("OriginalCFrame", Child.CFrame)

			-- Set initial size to very small instead of zero
			Child.Size = Vector3.new(0.001, 0.001, 0.001)
		end
	end

	-- Store plant type for later reference
	PlantModel:SetAttribute("PlantType", PlantType)

	-- Apply individual fruit RNG
	local FruitCount = 0
	local TotalFruitValue = 0
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") and string.match(Child.Name, "Fruit_%d+") then
			local FruitName, FruitSize, FruitValue = self:ApplyFruitRNG(Child, PlantType)
			FruitCount = FruitCount + 1
			TotalFruitValue = TotalFruitValue + FruitValue
		end
	end

	-- Store fruit system info
	PlantModel:SetAttribute("FruitCount", FruitCount)
	PlantModel:SetAttribute("TotalFruitValue", TotalFruitValue)

	return true
end

-- Start fruit regrowth cycle for individual fruits
function PlantGrower:StartFruitRegrowth(PlantModel)
	local PlantType = PlantModel:GetAttribute("PlantType")
	local Config = PlantStages:GetPlantConfig(PlantType)

	if not Config.fruitSystem or not Config.fruitSystem.enabled then
		return
	end

	-- Check each fruit individually
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") and string.match(Child.Name, "Fruit_%d+") then
			local RegrowthsRemaining = Child:GetAttribute("RegrowthsRemaining") or 0
			if RegrowthsRemaining > 0 then
				-- Start regrowth cycle for this specific fruit
				task.spawn(function()
					self:RegrowSingleFruit(Child, PlantType, Config.fruitSystem.regrowthTime)
				end)
			end
		end
	end
end

-- Regrow a single fruit part
function PlantGrower:RegrowSingleFruit(FruitPart, PlantType, RegrowthTime)
	local RegrowthsRemaining = FruitPart:GetAttribute("RegrowthsRemaining") or 0
	if RegrowthsRemaining <= 0 then
		return
	end

	-- Wait for regrowth time
	task.wait(RegrowthTime)

	-- Reset fruit to tiny size
	FruitPart.Size = Vector3.new(0.001, 0.001, 0.001)

	-- Apply new RNG for this regrowth
	local FruitName, FruitSize, FruitValue = self:ApplyFruitRNG(FruitPart, PlantType)

	-- Grow the fruit
	local Config = PlantStages:GetPlantConfig(PlantType)
	local Duration = Config.partGrowDuration or 2
	self:GrowPart(FruitPart, Duration, Config.easingStyle, Config.easingDirection, Config.growthMode, Config.smoothness)

	-- Update fruit's regrowth count
	FruitPart:SetAttribute("RegrowthsRemaining", RegrowthsRemaining - 1)

	-- Schedule next regrowth if available
	if RegrowthsRemaining - 1 > 0 then
		task.spawn(function()
			self:RegrowSingleFruit(FruitPart, PlantType, RegrowthTime)
		end)
	end
end

function PlantGrower:ScaleChildParts(ParentPart, Progress)
	-- Scale all child parts based on growth progress (0 to 1)
	for _, Child in pairs(ParentPart:GetChildren()) do
		if Child:IsA("BasePart") then
			local TargetSize = Child:GetAttribute("TargetSize")
			local OriginalCFrame = Child:GetAttribute("OriginalCFrame")

			if TargetSize and OriginalCFrame then
				-- Scale from tiny to target size based on progress
				local TinySize = Vector3.new(0.001, 0.001, 0.001)
				local CurrentSize = TinySize:Lerp(TargetSize, Progress)
				Child.Size = CurrentSize

				-- Scale the position relative to parent (keep it simple)
				local ParentCFrame = ParentPart.CFrame
				local OriginalRelativePos = ParentCFrame:ToObjectSpace(OriginalCFrame).Position
				local ScaledRelativePos = OriginalRelativePos * Progress

				-- Maintain original rotation
				local OriginalRotation = ParentCFrame:ToObjectSpace(OriginalCFrame) - ParentCFrame:ToObjectSpace(OriginalCFrame).Position
				Child.CFrame = ParentCFrame * CFrame.new(ScaledRelativePos) * OriginalRotation

				-- Recursively scale any children of this child
				self:ScaleChildParts(Child, Progress)
			end
		end
	end
end

-- Modified GrowPart function (replace the existing one):
function PlantGrower:GrowPart(Part, Duration, EasingStyle, EasingDirection, GrowthMode, Smoothness)
	if not Part or not Part:IsA("BasePart") then
		warn("Invalid part provided to GrowPart")
		return
	end

	local TargetSize = Part:GetAttribute("TargetSize")
	local OriginalCFrame = Part:GetAttribute("OriginalCFrame")

	if not TargetSize or not OriginalCFrame then
		warn("Part " .. Part.Name .. " missing required attributes")
		return
	end

	GrowthMode = GrowthMode or "uniform"
	Smoothness = Smoothness or "smooth"

	-- Check if this part has child parts that need to scale with it
	local HasChildParts = false
	for _, Child in pairs(Part:GetChildren()) do
		if Child:IsA("BasePart") then
			HasChildParts = true
			break
		end
	end

	-- Calculate the base position (bottom of the part using UpVector)
	local BasePosition = OriginalCFrame.Position - (OriginalCFrame.UpVector * (TargetSize.Y / 2))

	local StartSize
	if GrowthMode == "directional" then
		StartSize = Vector3.new(TargetSize.X, 0.001, TargetSize.Z)
	else
		StartSize = Vector3.new(0.001, 0.001, 0.001)
	end

	-- Determine update frequency based on smoothness
	local UpdateInterval
	if Smoothness == "smooth" then
		UpdateInterval = 0
	elseif Smoothness == "stepped" then
		UpdateInterval = 1/30
	elseif Smoothness == "chunky" then
		UpdateInterval = 1/15
	else
		UpdateInterval = 0
	end

	local RunService = game:GetService("RunService")
	local StartTime = tick()
	local LastUpdateTime = 0
	local BaselineDuration = Duration or 1
	local ElapsedGrowthTime = 0

	local Connection
	Connection = RunService.Heartbeat:Connect(function()
		local CurrentTime = tick()

		if UpdateInterval > 0 and (CurrentTime - LastUpdateTime) < UpdateInterval then
			return
		end
		LastUpdateTime = CurrentTime

		local PlantModel = Part.Parent
		local CurrentMultiplier = self:GetGrowthSpeedMultiplier(PlantModel)
		local AdjustedDuration = BaselineDuration / CurrentMultiplier

		local DeltaTime = CurrentTime - StartTime
		ElapsedGrowthTime = ElapsedGrowthTime + (DeltaTime * CurrentMultiplier)
		StartTime = CurrentTime

		local Progress = math.min(ElapsedGrowthTime / BaselineDuration, 1)
		local EasedProgress = 1 - (1 - Progress) * (1 - Progress)

		if Smoothness == "stepped" then
			EasedProgress = math.floor(EasedProgress * 20) / 20
		elseif Smoothness == "chunky" then
			EasedProgress = math.floor(EasedProgress * 8) / 8
		end

		local CurrentSize
		if GrowthMode == "directional" then
			CurrentSize = Vector3.new(
				TargetSize.X,
				StartSize.Y + (TargetSize.Y - StartSize.Y) * EasedProgress,
				TargetSize.Z
			)
		else
			CurrentSize = StartSize:Lerp(TargetSize, EasedProgress)
		end

		Part.Size = CurrentSize

		-- Scale child parts if they exist
		if HasChildParts then
			self:ScaleChildParts(Part, EasedProgress)
		end

		local NewCenterPosition = BasePosition + (OriginalCFrame.UpVector * (CurrentSize.Y / 2))
		Part.CFrame = CFrame.fromMatrix(NewCenterPosition, OriginalCFrame.RightVector, OriginalCFrame.UpVector)

		if Progress >= 1 then
			Connection:Disconnect()
			Part.Size = TargetSize

			-- Final scaling for child parts
			if HasChildParts then
				self:ScaleChildParts(Part, 1.0) -- Full growth (100%)
			end

			local FinalCenterPosition = BasePosition + (OriginalCFrame.UpVector * (TargetSize.Y / 2))
			Part.CFrame = CFrame.fromMatrix(FinalCenterPosition, OriginalCFrame.RightVector, OriginalCFrame.UpVector)
		end
	end)

	local CompletedEvent = Instance.new("BindableEvent")

	task.spawn(function()
		while Connection and Connection.Connected do
			task.wait()
		end
		CompletedEvent:Fire()
	end)

	return {
		Completed = CompletedEvent.Event
	}
end

-- Calculate dynamic timing based on part sizes
function PlantGrower:CalculatePartTimings(PlantModel, PlantType)
	local Stages = PlantStages:GetPlantStages(PlantType)
	local Config = PlantStages:GetPlantConfig(PlantType)

	if Config.timingMode ~= "dynamic" then
		return nil -- Use static timing
	end

	-- Count total number of parts (since they grow sequentially)
	local TotalParts = 0
	local PartComplexity = {}
	local TotalComplexity = 0

	for StageName, Parts in pairs(Stages) do
		for _, PartName in pairs(Parts) do
			local Part = PlantModel:FindFirstChild(PartName, true)
			if Part then
				local TargetSize = Part:GetAttribute("TargetSize")
				if TargetSize then
					-- Calculate complexity based on volume (bigger parts take longer)
					local Volume = TargetSize.X * TargetSize.Y * TargetSize.Z
					local Complexity = math.sqrt(Volume) -- Square root to prevent huge differences

					PartComplexity[PartName] = Complexity
					TotalComplexity = TotalComplexity + Complexity
					TotalParts = TotalParts + 1
				end
			end
		end
	end

	-- Account for delays between parts (0.05 seconds each)
	local TotalDelayTime = (TotalParts - 1) * 0.05
	local AvailableGrowthTime = Config.totalBloomTime - TotalDelayTime

	-- Ensure we have positive time for growth
	if AvailableGrowthTime <= 0 then
		AvailableGrowthTime = Config.totalBloomTime * 0.9 -- Use 90% if delays would exceed total time
	end

	-- Calculate time allocation for each part (first pass)
	local PartTimings = {}
	local TotalAssignedTime = 0
	local CappedParts = {}
	local UncappedParts = {}

	for PartName, Complexity in pairs(PartComplexity) do
		local TimeRatio = Complexity / TotalComplexity
		local PartTime = AvailableGrowthTime * TimeRatio

		if PartTime > 20 then
			-- Cap this part and track the excess time
			CappedParts[PartName] = 20
			local ExcessTime = PartTime - 20
			TotalAssignedTime = TotalAssignedTime + 20

			-- Track uncapped parts to redistribute excess time to
			for OtherPartName, OtherComplexity in pairs(PartComplexity) do
				if OtherPartName ~= PartName then
					local OtherTimeRatio = OtherComplexity / TotalComplexity
					local OtherPartTime = AvailableGrowthTime * OtherTimeRatio
					if OtherPartTime <= 20 then
						UncappedParts[OtherPartName] = OtherPartTime
					end
				end
			end
		else
			PartTime = math.max(0.2, PartTime) -- Only apply minimum
			PartTimings[PartName] = PartTime
			TotalAssignedTime = TotalAssignedTime + PartTime
		end
	end

	-- Add capped parts to final timings
	for PartName, Time in pairs(CappedParts) do
		PartTimings[PartName] = Time
	end

	-- If we have excess time, redistribute it proportionally to uncapped parts
	local ExcessTime = AvailableGrowthTime - TotalAssignedTime
	if ExcessTime > 0 and next(UncappedParts) then
		local UncappedComplexity = 0
		for PartName, _ in pairs(UncappedParts) do
			UncappedComplexity = UncappedComplexity + PartComplexity[PartName]
		end

		for PartName, _ in pairs(UncappedParts) do
			local RedistributionRatio = PartComplexity[PartName] / UncappedComplexity
			local BonusTime = ExcessTime * RedistributionRatio
			PartTimings[PartName] = PartTimings[PartName] + BonusTime
			TotalAssignedTime = TotalAssignedTime + BonusTime
		end
	end

	return PartTimings
end

-- Grow an entire plant through all its stages
function PlantGrower:GrowPlant(PlantModel, PlantType)
	if not PlantStages:IsValidPlantType(PlantType) then
		warn("Invalid plant type: " .. tostring(PlantType))
		return
	end

	local Stages = PlantStages:GetPlantStages(PlantType)
	local Config = PlantStages:GetPlantConfig(PlantType)

	if not Stages or not Config then
		warn("Missing stages or config for plant type: " .. PlantType)
		return
	end

	-- Initialize the plant (includes RNG)
	self:InitializePlant(PlantModel, PlantType)

	-- Calculate dynamic timings if enabled
	local PartTimings = self:CalculatePartTimings(PlantModel, PlantType)

	-- Apply growth speed modifiers to all part timings
	local SpeedMultiplier = self:GetGrowthSpeedMultiplier(PlantModel)
	if PartTimings and SpeedMultiplier ~= 1.0 then
		for PartName, Duration in pairs(PartTimings) do
			PartTimings[PartName] = Duration / SpeedMultiplier -- Faster growth = shorter duration
		end
	end

	-- Get stage names in order (Stage1, Stage2, etc.)
	local StageNames = {}
	for StageName, _ in pairs(Stages) do
		table.insert(StageNames, StageName)
	end

	-- Sort stages by their number
	table.sort(StageNames, function(A, B)
		local NumA = tonumber(string.match(A, "%d+"))
		local NumB = tonumber(string.match(B, "%d+"))
		return (NumA or 0) < (NumB or 0)
	end)

	for _, StageName in pairs(StageNames) do
		local Parts = Stages[StageName]

		if Parts then
			-- Grow parts sequentially within this stage
			for _, PartName in pairs(Parts) do
				local Part = PlantModel:FindFirstChild(PartName, true)
				if Part then
					-- Use dynamic timing if available, otherwise fallback to config
					local PartDuration = PartTimings and PartTimings[PartName] or Config.partGrowDuration or 1.5

					-- Apply speed multiplier to static timing if no dynamic timing
					if not PartTimings then
						local SpeedMultiplier = self:GetGrowthSpeedMultiplier(PlantModel)
						PartDuration = PartDuration / SpeedMultiplier
					end

					local Tween = self:GrowPart(
						Part, 
						PartDuration,
						Config.easingStyle,
						Config.easingDirection,
						Config.growthMode,
						Config.smoothness -- Pass the smoothness setting
					)

					if Tween then
						-- Wait for this part to finish growing before moving to next
						Tween.Completed:Wait()

						-- Small delay between parts for natural effect
						task.wait(0.05)
					end
				else
					warn("Part not found: " .. PartName)
				end
			end
		end
	end

	-- Start fruit regrowth cycle if this plant has fruits
	local Config = PlantStages:GetPlantConfig(PlantType)
	if Config.fruitSystem and Config.fruitSystem.enabled then
		task.spawn(function()
			self:StartFruitRegrowth(PlantModel)
		end)
	end
end

-- Set plant health state and apply visual effects
function PlantGrower:SetPlantHealth(PlantModel, HealthState)
	local HealthData = PlantStages.HealthSystem.HealthStates[HealthState]
	if not HealthData then
		warn("Invalid health state: " .. tostring(HealthState))
		return
	end

	-- Store health state
	warn(HealthState)
	PlantModel:SetAttribute("HealthState", HealthState)

	-- Apply color tint to all parts
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") then
			-- Store original color if not already stored
			if not Child:GetAttribute("OriginalColor") then
				Child:SetAttribute("OriginalColor", Child.Color)
			end

			-- Apply health tint to original color
			local OriginalColor = Child:GetAttribute("OriginalColor")
			local TintedColor = Color3.new(
				OriginalColor.R * HealthData.colorTint.R,
				OriginalColor.G * HealthData.colorTint.G,
				OriginalColor.B * HealthData.colorTint.B
			)
			Child.Color = TintedColor
		end
	end
end

-- Add growth modifier to plant
function PlantGrower:AddGrowthModifier(PlantModel, ModifierName)
	local ModifierData = PlantStages.HealthSystem.GrowthModifiers[ModifierName]
	if not ModifierData then
		warn("Invalid growth modifier: " .. tostring(ModifierName))
		return
	end

	-- Store modifier as individual attribute with "Modifier_" prefix
	PlantModel:SetAttribute("Modifier_" .. ModifierName, ModifierData.multiplier)
end

-- Remove growth modifier from plant
function PlantGrower:RemoveGrowthModifier(PlantModel, ModifierName)
	-- Remove the modifier attribute
	PlantModel:SetAttribute("Modifier_" .. ModifierName, nil)
end

-- Calculate total growth speed multiplier
function PlantGrower:GetGrowthSpeedMultiplier(PlantModel)
	local TotalMultiplier = 1.0

	-- Apply health state multiplier
	local HealthState = PlantModel:GetAttribute("HealthState") or "Healthy"
	local HealthData = PlantStages.HealthSystem.HealthStates[HealthState]
	if HealthData then
		TotalMultiplier = TotalMultiplier * HealthData.growthMultiplier
	end

	-- Apply growth modifier multipliers by checking all modifier attributes
	for AttributeName, Value in pairs(PlantModel:GetAttributes()) do
		if string.sub(AttributeName, 1, 9) == "Modifier_" and Value then
			TotalMultiplier = TotalMultiplier * Value
		end
	end

	return TotalMultiplier
end

-- Get growth progress of a plant (0 to 1)
function PlantGrower:GetGrowthProgress(PlantModel)
	local TotalParts = 0
	local GrownParts = 0

	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") and Child:GetAttribute("TargetSize") then
			TotalParts = TotalParts + 1

			local TargetSize = Child:GetAttribute("TargetSize")
			local CurrentSize = Child.Size

			-- Consider a part "grown" if it's at least 90% of target size
			if CurrentSize.Magnitude >= TargetSize.Magnitude * 0.9 then
				GrownParts = GrownParts + 1
			end
		end
	end

	return TotalParts > 0 and (GrownParts / TotalParts) or 0
end

-- Get plant summary (useful for UI display)
function PlantGrower:GetPlantSummary(PlantModel)
	local PlantType = PlantModel:GetAttribute("PlantType") or "Unknown"
	local SizeName = PlantModel:GetAttribute("PlantSizeName") or "Normal"
	local SizeMultiplier = PlantModel:GetAttribute("PlantSizeMultiplier") or 1.0
	local FruitCount = PlantModel:GetAttribute("FruitCount") or 0
	local TotalFruitValue = PlantModel:GetAttribute("TotalFruitValue") or 0

	-- Get individual fruit regrowth info
	local FruitDetails = {}
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") and string.match(Child.Name, "Fruit_%d+") then
			table.insert(FruitDetails, {
				Name = Child.Name,
				SizeName = Child:GetAttribute("FruitSizeName") or "Normal",
				Value = Child:GetAttribute("FruitValue") or 0,
				RegrowthsRemaining = Child:GetAttribute("RegrowthsRemaining") or 0
			})
		end
	end

	return {
		PlantType = PlantType,
		SizeName = SizeName,
		SizeMultiplier = SizeMultiplier,
		FruitCount = FruitCount,
		TotalFruitValue = TotalFruitValue,
		FruitDetails = FruitDetails,
		Progress = self:GetGrowthProgress(PlantModel)
	}
end

-- Harvest a specific fruit and start regrowth
function PlantGrower:HarvestFruit(PlantModel, FruitName)
	-- Get the base fruit name (e.g., "Fruit_01" from "Fruit_01_Cap")
	local BaseFruitName = string.match(FruitName, "Fruit_%d+")
	if not BaseFruitName then
		BaseFruitName = FruitName -- Single part fruit
	end

	-- Find and reset all parts belonging to this specific fruit
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") then
			local ChildBaseName = string.match(Child.Name, "Fruit_%d+")
			-- Match either the exact name or the base fruit name for multi-part fruits
			if Child.Name == FruitName or ChildBaseName == BaseFruitName then
				-- Reset fruit part to tiny size for regrowth
				Child.Size = Vector3.new(0.001, 0.001, 0.001)

				-- Also reset any child parts (nested parts inside the fruit)
				for _, ChildPart in pairs(Child:GetChildren()) do
					if ChildPart:IsA("BasePart") then
						ChildPart.Size = Vector3.new(0.001, 0.001, 0.001)
					end
				end
			end
		end
	end

	-- Start regrowth cycle for this fruit
	self:StartFruitRegrowth(PlantModel)
end

-- Reset a plant to its initial state
function PlantGrower:ResetPlant(PlantModel)
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") and Child:GetAttribute("TargetSize") then
			Child.Size = Vector3.new(0.001, 0.001, 0.001)

			-- Restore original position if stored
			local OriginalCFrame = Child:GetAttribute("OriginalCFrame")
			if OriginalCFrame then
				Child.CFrame = OriginalCFrame
			end

			-- Restore original color if stored
			local OriginalColor = Child:GetAttribute("OriginalColor")
			if OriginalColor then
				Child.Color = OriginalColor
			end
		end
	end

	-- Reset health and modifiers
	PlantModel:SetAttribute("HealthState", "Healthy")

	-- Remove all modifier attributes
	for AttributeName, _ in pairs(PlantModel:GetAttributes()) do
		if string.sub(AttributeName, 1, 9) == "Modifier_" then
			PlantModel:SetAttribute(AttributeName, nil)
		end
	end

	-- Reset RNG and fruit attributes
	PlantModel:SetAttribute("PlantSizeMultiplier", nil)
	PlantModel:SetAttribute("PlantSizeName", nil)
	PlantModel:SetAttribute("FruitCount", nil)
	PlantModel:SetAttribute("TotalFruitValue", nil)

	-- Reset individual fruit attributes
	for _, Child in pairs(PlantModel:GetDescendants()) do
		if Child:IsA("BasePart") and string.match(Child.Name, "Fruit_%d+") then
			Child:SetAttribute("FruitSizeName", nil)
			Child:SetAttribute("FruitValue", nil)
			Child:SetAttribute("FruitSizeMultiplier", nil)
			Child:SetAttribute("RegrowthsRemaining", nil)
		end
	end

	-- Reset plant scale to 1
	PlantModel:ScaleTo(1)
end

return PlantGrower