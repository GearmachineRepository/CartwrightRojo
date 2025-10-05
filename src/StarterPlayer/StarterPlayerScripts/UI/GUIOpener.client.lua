--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Events = ReplicatedStorage:WaitForChild("Events")
local GuiEvents = Events:WaitForChild("GuiEvents")
local OpenGuiRemote = GuiEvents:WaitForChild("OpenGui") :: RemoteEvent

OpenGuiRemote.OnClientEvent:Connect(function(GuiName: string)
	local TargetGui = PlayerGui:FindFirstChild(GuiName)

	if TargetGui and TargetGui:IsA("ScreenGui") then
		TargetGui.Enabled = true
	else
		warn("[GuiOpener] GUI not found:", GuiName)
	end
end)