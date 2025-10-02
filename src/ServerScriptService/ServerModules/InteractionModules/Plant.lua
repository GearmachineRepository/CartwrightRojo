--!strict
local Plant = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ToolInstancer = require(Modules:WaitForChild("ToolInstancer"))
local SoundPlayer = require(Modules:WaitForChild("SoundPlayer"))
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))

-- StateA: Uproot (plant in ground)
function Plant.StateAFunction(player: Player, plant: Instance, config: any)
	if not plant:IsA("Model") then return end

	-- Check if can be interacted with
	if not ObjectStateManager.CanTransition(plant, "Interacting") then
		return
	end

	-- Brief interaction state
	ObjectStateManager.SetState(plant, "Interacting", {Player = player.Name})

	if config and config.InteractionSound then
		SoundPlayer.PlaySound(config.InteractionSound, plant.PrimaryPart, {
			Volume = 0.5,
			PlaybackSpeed = 0.9 + math.random() * 0.2
		})
	end

	-- Uproot animation could go here
	task.wait(0.3)

	-- Change to StateB (uprooted, on ground)
	plant:SetAttribute("CurrentState", "StateB")
	ObjectStateManager.ForceIdle(plant)
end

-- StateB: Pickup (plant uprooted, lying on ground)
function Plant.StateBFunction(player: Player, plant: Instance, config: any)
	if not plant:IsA("Model") then return end

	-- Check if can be picked up
	if not ObjectStateManager.CanTransition(plant, "Equipped") then
		return
	end

	-- Set equipped state
	ObjectStateManager.SetState(plant, "Equipped")

	if config and config.InteractionSound then
		SoundPlayer.PlaySound(config.InteractionSound, plant.PrimaryPart, {
			Volume = 0.3
		})
	end

	-- Convert to tool
	ToolInstancer.Pickup(player, plant, config)
end

return Plant