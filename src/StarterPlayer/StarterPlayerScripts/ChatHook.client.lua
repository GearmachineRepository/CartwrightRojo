--!strict
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if TextChatService.BubbleChatConfiguration then
	TextChatService.BubbleChatConfiguration.Enabled = false
end

local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogTypewriter = require(Modules:WaitForChild("DialogTypewriter"))

local ProcessedMessages = {}

TextChatService.OnIncomingMessage = function(Message: TextChatMessage)
	local Props = Instance.new("TextChatMessageProperties")
	
	if not Message.TextSource then return Props end
	
	local MessageId = Message.MessageId
	if ProcessedMessages[MessageId] then
		return Props
	end
	ProcessedMessages[MessageId] = true
	task.delay(5, function()
		ProcessedMessages[MessageId] = nil
	end)
	
	local Speaker = Players:GetPlayerByUserId(Message.TextSource.UserId)
	if not Speaker then return Props end
	
	task.defer(function()
		local Character = Speaker.Character
		if not Character then return end
		
		local FilteredText = Props.Text
		if FilteredText == "" then
			FilteredText = Message.Text
		end
		
		DialogTypewriter:PlayDialog(Character, FilteredText)
	end)
	
	return Props
end

print("[ChatHook] Client initialized - Bubble chat ready!")