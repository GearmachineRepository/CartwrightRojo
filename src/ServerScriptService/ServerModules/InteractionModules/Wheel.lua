--!strict
local Wheel = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ToolInstancer = require(Modules:WaitForChild("ToolInstancer"))
local SoundPlayer = require(Modules:WaitForChild("SoundPlayer"))
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))

-- Wheels work like items: pickup on interact
function Wheel.StateAFunction(player: Player, wheel: Instance, config: any)
	if not wheel:IsA("Model") then return end

	if not ObjectStateManager.CanTransition(wheel, "Equipped") then
		return
	end

	ObjectStateManager.SetState(wheel, "Equipped")

	if config and config.InteractionSound then
		SoundPlayer.PlaySound(config.InteractionSound, wheel.PrimaryPart, {
			Volume = 0.5,
			PlaybackSpeed = 0.8 + math.random() * 0.4
		})
	end

	ToolInstancer.Pickup(player, wheel, config)
end

function Wheel.StateBFunction(player: Player, wheel: Instance, config: any)
	Wheel.StateAFunction(player, wheel, config)
end
return Wheel