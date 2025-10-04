--!strict
local Cauldron = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local RecipeChecker = require(Modules:WaitForChild("RecipeChecker"))
local ToolInstancer = require(Modules:WaitForChild("ToolInstancer"))
local SoundPlayer = require(Modules:WaitForChild("SoundPlayer"))
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))

local BREWING_DURATION = 3

local function GetPartsInBounds(cauldron: Model): {Instance}
	local bounds, size = cauldron:GetBoundingBox()
	local region = Region3.new(bounds.Position - size/2, bounds.Position + size/2)
	region = region:ExpandToGrid(4)

	local parts = workspace:GetPartBoundsInBox(region.CFrame, region.Size, function(part)
		return not cauldron:IsAncestorOf(part)
	end)
	return parts
end

function Cauldron.StateAFunction(player: Player, cauldron: Instance, config: any)
	if not cauldron:IsA("Model") then return end

	-- Check if can transition to Interacting state
	if not ObjectStateManager.CanTransition(cauldron, "Interacting") then
		warn("[Cauldron] Cannot start brewing - cauldron busy")
		return
	end

	local parts = GetPartsInBounds(cauldron)
	local recipeResult = RecipeChecker.CheckRecipes("Cauldron", parts)

	if not recipeResult then
		warn("[Cauldron] No valid recipe found")
		return
	end

	-- Set Interacting state using ObjectStateManager
	ObjectStateManager.SetState(cauldron, "Interacting", {Player = player.Name})

	if config and config.InteractionSound then
		SoundPlayer.PlaySound(config.InteractionSound, cauldron.PrimaryPart)
	end

	task.spawn(function()
		task.wait(BREWING_DURATION)

		-- Destroy ingredients
		if recipeResult.modelsToDestroy then
			for _, model in ipairs(recipeResult.modelsToDestroy) do
				if model and model.Parent then
					model:Destroy()
				end
			end
		end

		-- Create result potion
		if recipeResult.recipe and recipeResult.recipe.result then
			local resultPosition = cauldron:GetPivot().Position + Vector3.new(0, 3, 0)
			ToolInstancer.Create(recipeResult.recipe.result, CFrame.new(resultPosition))
		end

		-- Return to idle state
		ObjectStateManager.ForceIdle(cauldron)
	end)
end

return Cauldron