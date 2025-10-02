-- StarterPlayerScripts/DialogBubbles.client.lua
-- Renders typewriter bubbles for ALL chat messages (client-side per player)

local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Optional: hide default bubbles on this client
if TextChatService.BubbleChatConfiguration then
	TextChatService.BubbleChatConfiguration.Enabled = false
end

local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogTypewriter = require(Modules:WaitForChild("DialogTypewriter"))

-- De-dupe guard (handles rare double-calls)
local seen = {}

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local props = Instance.new("TextChatMessageProperties")
	-- If you want to hide the chat line entirely, uncomment:
	-- props.Text = ""

	local src = message.TextSource
	if not src then return props end

	-- Avoid double-render if callback fires twice
	if message.MessageId and seen[message.MessageId] then
		return props
	end
	seen[message.MessageId] = true
	task.delay(10, function() seen[message.MessageId] = nil end)

	local speaker = Players:GetPlayerByUserId(src.UserId)
	if not speaker then return props end

	local function show(char: Model)
		DialogTypewriter:PlayDialog(char, message.Text)
	end

	local char = speaker.Character
	if char then
		task.defer(show, char)
	else
		-- If the character isn’t spawned yet, try once when it appears
		local conn; conn = speaker.CharacterAdded:Connect(function(c)
			conn:Disconnect()
			show(c)
		end)
	end

	return props
end
