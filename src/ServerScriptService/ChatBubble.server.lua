--!strict
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

TextChatService.BubbleChatConfiguration.Enabled = false

local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogTypewriter = require(Modules:WaitForChild("DialogTypewriter"))

local function onMessage(message: TextChatMessage)
	local src = message.TextSource
	if not src then return end

	local player = Players:GetPlayerByUserId(src.UserId)
	if not player then return end
	local character = player.Character
	if not character then return end

	DialogTypewriter:PlayDialog(character, message.Text, 0.05)
end

TextChatService.MessageReceived:Connect(onMessage)
