--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ToolInstancer = require(Modules:WaitForChild("ToolInstancer"))

return {
	StateAFunction = ToolInstancer.Pickup,
	StateBFunction = ToolInstancer.Pickup,
}