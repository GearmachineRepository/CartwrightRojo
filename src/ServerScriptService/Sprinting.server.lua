--!strict
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SprintEvents = ReplicatedStorage:WaitForChild("Events"):WaitForChild("SprintEvents")
local StartSprint = SprintEvents:WaitForChild("StartSprint")
local StopSprint = SprintEvents:WaitForChild("StopSprint")

local MAX_STAMINA = 100
local SPRINT_DRAIN_RATE = 20
local STAMINA_REGEN_RATE = 20
local STAMINA_REGEN_DELAY = 1.5
local MIN_STAMINA_TO_SPRINT = 10

-- Stores stamina and sprint state for each player
local PlayerData: {[Player]: {
	Stamina: number,
	IsSprinting: boolean,
	LastSprintTime: number,
	Regenerating: boolean
}} = {}

StartSprint.OnServerEvent:Connect(function(player)
	local data = PlayerData[player]
	if not data then return end

	if data.Stamina >= MIN_STAMINA_TO_SPRINT then
		data.IsSprinting = true
		player:SetAttribute("Sprinting", true)
	end
end)

StopSprint.OnServerEvent:Connect(function(player)
	local data = PlayerData[player]
	if not data then return end

	data.IsSprinting = false
	player:SetAttribute("Sprinting", false)
end)

RunService.Heartbeat:Connect(function(dt)
	for player, data in pairs(PlayerData) do
		if data.IsSprinting then
			if data.Stamina > 0 then
				data.Stamina = math.max(0, data.Stamina - (SPRINT_DRAIN_RATE * dt))
				data.LastSprintTime = tick()
				data.Regenerating = false
			else
				data.IsSprinting = false
				player:SetAttribute("Sprinting", false)
			end
		else
			if tick() - data.LastSprintTime >= STAMINA_REGEN_DELAY then
				data.Regenerating = true
			end
			if data.Regenerating then
				data.Stamina = math.min(MAX_STAMINA, data.Stamina + (STAMINA_REGEN_RATE * dt))
			end
		end

        player:SetAttribute("Stamina", data.Stamina)
	end
end)

Players.PlayerAdded:Connect(function(player)
	PlayerData[player] = {
		Stamina = MAX_STAMINA,
		IsSprinting = false,
		LastSprintTime = 0,
		Regenerating = true
	}
end)

Players.PlayerRemoving:Connect(function(player)
	PlayerData[player] = nil
end)
