-- Module containing growth stage definitions for different plants

local PlantStages = {}

-- Define growth stages for different plant types
PlantStages.Plants = {

	["Day Flower"] = {
		Stage1 = {"Stem_01"},
		Stage2 = {"Stem_02", "Leaf_01", "Leaf_02"},
		Stage3 = {"Stem_03", "Leaf_03", "Leaf_04"},
		Stage4 = {"Stem_04", "Leaf_05", "Leaf_06"},
		Stage5 = {"Stem_05"},
		Stage6 = {"Stem_06"},
		Stage7 = {"Stem_07"},
		Stage8 = {"Stem_08", "Petal_01", "Center_01"},
		Stage9 = {"Petal_02", "Petal_04", "Petal_06", "Petal_08", "Petal_10", "Petal_12", "Petal_14", "Petal_16"},
		Stage10 = { "Petal_03", "Petal_05", "Petal_07", "Petal_09", "Petal_11", "Petal_13", "Petal_15", "Petal_17"}
	},

	["Offering Tree"] = {
		Stage1 = {"Stem_01"},
		Stage2 = {"Stem_02"},
		Stage3 = {"Stem_03"},
		Stage4 = {"Stem_04", "Stem_05", "Stem_06"},
		Stage5 = {"Stem_07", "Stem_08", "Stem_09"},
		Stage6 = {"Stem_10", "Stem_11", "Stem_12"},
		Stage7 = {"Leaf_01", "Stem_13", "Stem_14"},
		Stage8 = {"Stem_15", "Stem_16"},
		Stage9 = {"Leaf_02", "Stem_17", "Stem_18"},
		Stage10 = {"Stem_19", "Stem_20"},
		Stage11 = {"Leaf_03", "Stem_21", "Stem_22"},
		Stage12 = {"Stem_23", "Stem_24"},
		Stage13 = {"Leaf_04", "Stem_25"},
		Stage14 = {"Leaf_05", "Stem_26", "Stem_27"},
		Stage15 = {"Stem_28"},
		Stage16 = {"Leaf_06", "Stem_29", "Stem_30"},
		Stage17 = {"Leaf_07"},
		Stage18 = {"Leaf_08"},
		Stage19 = {"Fruit_01", "Fruit_02", "Fruit_03"},
	},

	Carrot = {
		Stage1 = {"Root_01", "Leaf_01"},
		Stage2 = {"Root_02", "Leaf_02", "Leaf_03"},
		Stage3 = {"Root_03", "Leaf_04", "Leaf_05"},
		Stage4 = {"Root_04", "Leaf_06", "Leaf_07"}
	},

	TomatoPlant = {
		Stage1 = {"Stem_01", "Root_01"},
		Stage2 = {"Stem_02", "Leaf_01", "Leaf_02"},
		Stage3 = {"Stem_03", "Branch_01", "Leaf_03", "Leaf_04"},
		Stage4 = {"Flower_01", "Flower_02", "Leaf_05"},
		Stage5 = {"Fruit_01", "Fruit_02", "Leaf_06"}
	}
}

-- Configuration for growth timing
PlantStages.Config = {

	["Day Flower"] = {
		totalBloomTime = 30, -- Total seconds for entire plant to grow
		easingStyle = Enum.EasingStyle.Quad,
		easingDirection = Enum.EasingDirection.Out,
		growthMode = "directional", -- "directional" or "uniform"
		timingMode = "dynamic", -- "dynamic" (size-based) or "static" (fixed durations)
		smoothness = "chunky", -- "smooth", "stepped", or "chunky"

		-- RNG Size System
		sizeRNG = {
			enabled = true,
			-- Base chances for size multipliers (must add up to 100)
			baseChances = {
				{min = 0.6, max = 0.75, weight = 3, name = "Tiny"},
				{min = 0.76, max = 0.95, weight = 5, name = "Small"},  
				{min = 0.96, max = 1.15, weight = 80, name = "Normal"}, -- Massive weight
				{min = 1.16, max = 1.5, weight = 7.9, name = "Large"},
				{min = 1.51, max = 1.9, weight = 1, name = "Huge"},
				{min = 5, max = 15, weight = .1, name = "Giant"}
			},
			-- Modifier effects (adds to better outcome chances)
			modifierBonus = {
				Sprinkler = 10,   -- +10% chance for better sizes
				Fertilizer = 15,  -- +15% chance for better sizes
				Greenhouse = 12   -- +12% chance for better sizes
			}
		}
	},

	["Offering Tree"] = {
		totalBloomTime = 5, -- Total seconds for entire plant to grow
		easingStyle = Enum.EasingStyle.Quad,
		easingDirection = Enum.EasingDirection.Out,
		growthMode = "directional", -- "directional" or "uniform"
		timingMode = "dynamic", -- "dynamic" (size-based) or "static" (fixed durations)
		smoothness = "chunky", -- "smooth", "stepped", or "chunky"

		sizeRNG = {
			enabled = true,
			baseChances = {
				{min = 0.6, max = 0.75, weight = 3, name = "Tiny"},
				{min = 0.76, max = 0.95, weight = 5, name = "Small"},  
				{min = 0.96, max = 1.15, weight = 80, name = "Normal"}, -- Massive weight
				{min = 1.16, max = 1.5, weight = 7.9, name = "Large"},
				{min = 1.51, max = 1.9, weight = 1, name = "Huge"},
				{min = 5, max = 15, weight = .1, name = "Giant"}
			},
			modifierBonus = {
				Sprinkler = 8,
				Fertilizer = 12,
				Greenhouse = 10
			}
		}
	},

	Carrot = {
		totalBloomTime = 15, -- Total seconds for entire plant to grow
		easingStyle = Enum.EasingStyle.Quad,
		easingDirection = Enum.EasingDirection.Out,
		growthMode = "directional", -- "directional" or "uniform"
		timingMode = "dynamic", -- "dynamic" (size-based) or "static" (fixed durations)
		smoothness = "smooth", -- "smooth", "stepped", or "chunky"

		sizeRNG = {
			enabled = true,
			baseChances = {
				{min = 0.6, max = 0.75, weight = 5, name = "Tiny"},
				{min = 0.76, max = 0.95, weight = 5, name = "Small"},
				{min = 0.96, max = 1.15, weight = 80, name = "Normal"},
				{min = 1.16, max = 1.5, weight = 5, name = "Large"},
				{min = 1.51, max = 1.9, weight = 4, name = "Huge"},
				{min = 1.91, max = 2.6, weight = 1, name = "Giant"}
			},
			modifierBonus = {
				Sprinkler = 12,
				Fertilizer = 18,
				Greenhouse = 8
			}
		}
	},

	TomatoPlant = {
		totalBloomTime = 15, -- Total seconds for entire plant to grow
		easingStyle = Enum.EasingStyle.Quad,
		easingDirection = Enum.EasingDirection.Out,
		growthMode = "directional", -- "directional" or "uniform"
		timingMode = "dynamic", -- "dynamic" (size-based) or "static" (fixed durations)
		smoothness = "smooth", -- "smooth", "stepped", or "chunky"

		sizeRNG = {
			enabled = true,
			baseChances = {
				{min = 0.75, max = 0.85, weight = 25, name = "Small"},
				{min = 0.86, max = 1.15, weight = 45, name = "Normal"},
				{min = 1.16, max = 1.4, weight = 20, name = "Large"},
				{min = 1.41, max = 1.8, weight = 8, name = "Huge"},
				{min = 1.81, max = 2.3, weight = 2, name = "Massive"}
			},
			modifierBonus = {
				Sprinkler = 10,
				Fertilizer = 15,
				Greenhouse = 12
			}
		},

		-- Fruit regrowth configuration
		regrowthTime = 8,           -- 8 seconds between regrowths
		regrowthDuration = 2,       -- How long each regrowth takes to animate
		fruitValueMultiplier = 10,  -- Size * 10 = fruit value
		maxRegrowths = 3            -- How many times fruits can regrow after harvest
	}
}

-- Health and Growth Modifiers
PlantStages.HealthSystem = {
	-- Health states and their effects
	HealthStates = {
		Healthy = {
			colorTint = Color3.new(1, 1, 1), -- No tint (normal colors)
			growthMultiplier = 1.0,
			description = "Plant is thriving"
		},

		Stressed = {
			colorTint = Color3.new(0.9, 0.85, 0.7), -- Slightly yellowish
			growthMultiplier = 0.8,
			description = "Plant needs attention"
		},

		Sick = {
			colorTint = Color3.new(0.7, 0.5, 0.3), -- Brownish tint
			growthMultiplier = 0.5,
			description = "Plant is unhealthy"
		},

		Dying = {
			colorTint = Color3.new(0.4, 0.3, 0.2), -- Dark brown
			growthMultiplier = 0.1,
			description = "Plant is dying"
		}
	},

	-- Growth modifiers from external factors
	GrowthModifiers = {
		Sprinkler = {
			multiplier = 1.25,
			description = "Watered by sprinkler"
		},

		Fertilizer = {
			multiplier = 1.5,
			description = "Enhanced with fertilizer"
		},

		Sunlight = {
			multiplier = 1.15,
			description = "Optimal sunlight exposure"
		},

		Greenhouse = {
			multiplier = 1.3,
			description = "Protected environment"
		},

		Drought = {
			multiplier = 0.6,
			description = "Lack of water"
		},

		Frost = {
			multiplier = 0.3,
			description = "Cold damage"
		}
	}
}


-- Get stages for a specific plant type
function PlantStages:GetPlantStages(plantType)
	return self.Plants[plantType]
end

-- Get configuration for a specific plant type
function PlantStages:GetPlantConfig(plantType)
	return self.Config[plantType]
end

-- Get all available plant types
function PlantStages:GetPlantTypes()
	local types = {}
	for plantType, _ in pairs(self.Plants) do
		table.insert(types, plantType)
	end
	return types
end

-- Validate if a plant type exists
function PlantStages:IsValidPlantType(plantType)
	return self.Plants[plantType] ~= nil
end

return PlantStages