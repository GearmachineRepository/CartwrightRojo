--!strict
--!optimize 2
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local WindShake = require(Modules:WaitForChild("WindShake"))

task.wait(.1)
WindShake:Init({
	MatchWorkspaceWind = true,
})
