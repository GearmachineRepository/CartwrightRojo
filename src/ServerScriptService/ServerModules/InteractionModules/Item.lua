--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ToolInstancer = require(Modules:WaitForChild("ToolInstancer"))
local QuestProgressHandler = require(Modules:WaitForChild("QuestProgressHandler"))

local Item = {}

function Item.StateAFunction(Player: Player, Object: Instance, Config: any): ()
	if not Object:IsA("Model") then return end

	local ItemName = Object.Name

	ToolInstancer.Pickup(Player, Object, Config)

	QuestProgressHandler.OnItemPickup(Player, ItemName)
end

function Item.StateBFunction(Player: Player, Object: Instance, Config: any): ()
	if not Object:IsA("Model") then return end

	local ItemName = Object.Name

	ToolInstancer.Pickup(Player, Object, Config)

	QuestProgressHandler.OnItemPickup(Player, ItemName)
end

return Item