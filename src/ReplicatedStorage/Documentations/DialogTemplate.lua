--!strict
--[[
	SIMPLE DIALOG TEMPLATE

	This is a template for creating NPC dialogs without complex coding.
	Just fill in the DATA sections and delete what you don't need.

	STRUCTURE:
	1. NPC_INFO - Basic info about the NPC
	2. GREETINGS - What they say when you first talk to them
	3. QUEST_STUFF - Quest offers and turn-ins (optional)
	4. DIALOG_CHOICES - The conversation options

	Copy this file, rename it to your NPC's name, and fill it in!
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))
local QuestManager = require(Modules:WaitForChild("QuestManager"))
local DialogConditions = require(Modules:WaitForChild("DialogConditions"))

-- ═══════════════════════════════════════════════════════════
-- NPC INFO - Change this to match your NPC
-- ═══════════════════════════════════════════════════════════
local NPC_NAME = "NPCName"

-- ═══════════════════════════════════════════════════════════
-- GREETINGS - What the NPC says when you first talk
-- ═══════════════════════════════════════════════════════════
local GREETINGS = {
	Default = "Hello there!",

	-- If player has a quest active from this NPC
	ActiveQuest = {
		{Quest = "MyQuest", Text = "How's the quest going?"}
	},

	-- If player finished a quest before
	CompletedQuest = {
		{Quest = "MyQuest", Text = "Good to see you again!"}
	}
}

-- ═══════════════════════════════════════════════════════════
-- QUEST STUFF (Delete this section if no quests)
-- ═══════════════════════════════════════════════════════════
local QUEST_OFFERS = {
	{
		QuestId = "MyQuest",
		ButtonText = "Need any help?",
		OfferText = "I need someone to collect flowers for me.",
		Description = "Collect 10 red flowers and bring them back."
	}
}

local QUEST_TURN_INS = {
	{
		QuestId = "MyQuest",
		ButtonText = "I collected the flowers",
		ResponseText = "Thank you so much! Here's your reward."
	}
}

-- ═══════════════════════════════════════════════════════════
-- DIALOG CHOICES - The conversation tree
--
-- Each choice has:
--   Text = What the button says
--   Response = What the NPC says back
--   Choices = (Optional) More choices after this
--   Action = (Optional) What happens when selected
-- ═══════════════════════════════════════════════════════════
local DIALOG_TREE = {
	-- Simple choice with no follow-up
	{
		Text = "How are you?",
		Response = "I'm doing well, thanks for asking!"
	},

	-- Choice that leads to more choices (nested)
	{
		Text = "Tell me about yourself",
		Response = "I've lived here my whole life. What would you like to know?",
		Choices = {
			{
				Text = "What do you do?",
				Response = "I'm a farmer. Been growing crops for 20 years!"
			},
			{
				Text = "Do you like living here?",
				Response = "Oh yes, it's peaceful and quiet."
			}
		}
	},

	-- Choice with an action (sets a flag)
	{
		Text = "Can you help me?",
		Response = "Of course! What do you need?",
		Action = function(Player)
			DialogConditions.SetFlag(Player, "AskedForHelp", true)
		end
	},

	-- Choice that only shows if player has a flag
	{
		Text = "About that help...",
		Response = "Right, let me get that for you.",
		ShowIf = {
			Type = "Flag",
			Name = "AskedForHelp"
		}
	},

	-- Choice that gives an item
	{
		Text = "Can I have a potion?",
		Response = "Here you go!",
		Action = function(Player)
			local Potion = game.ServerStorage.Items:FindFirstChild("HealthPotion")
			if Potion then
				Potion:Clone().Parent = Player.Backpack
			end
		end
	},

	-- Always include goodbye!
	{
		Text = "Goodbye",
		Response = "See you later!"
	}
}

-- ═══════════════════════════════════════════════════════════
-- DON'T EDIT BELOW THIS LINE (unless you know what you're doing)
-- ═══════════════════════════════════════════════════════════

return function(Player: Player)
	-- Build greeting
	local ActiveGreetings = {}
	local CompletedGreetings = {}

	for _, Greeting in ipairs(GREETINGS.ActiveQuest or {}) do
		table.insert(ActiveGreetings, {QuestId = Greeting.Quest, Greeting = Greeting.Text})
	end

	for _, Greeting in ipairs(GREETINGS.CompletedQuest or {}) do
		table.insert(CompletedGreetings, {QuestId = Greeting.Quest, Greeting = Greeting.Text})
	end

	local GreetingText = DialogBuilder.BuildGreeting(NPC_NAME, Player, {
		DefaultGreeting = GREETINGS.Default,
		ActiveQuestGreetings = ActiveGreetings,
		CompletedQuestGreetings = CompletedGreetings
	})

	local Choices = {}

	-- Add quest turn-ins
	if QUEST_TURN_INS then
		local TurnIns = {}
		for _, TurnIn in ipairs(QUEST_TURN_INS) do
			table.insert(TurnIns, {
				QuestId = TurnIn.QuestId,
				Text = TurnIn.ButtonText,
				ResponseText = TurnIn.ResponseText
			})
		end
		DialogBuilder.AddQuestTurnIns(Choices, Player, TurnIns)
	end

	-- Add quest offers
	if QUEST_OFFERS then
		local Offers = {}
		for _, Offer in ipairs(QUEST_OFFERS) do
			table.insert(Offers, {
				QuestId = Offer.QuestId,
				OfferText = Offer.OfferText,
				ButtonText = Offer.ButtonText,
				QuestDescription = Offer.Description
			})
		end
		DialogBuilder.AddQuestOffers(Choices, Player, Offers)
	end

	-- Convert simple format to full format
	local function ConvertChoice(Choice)
		-- Check if should show
		if Choice.ShowIf then
			if Choice.ShowIf.Type == "Flag" then
				if not Player:GetAttribute("DialogFlag_" .. Choice.ShowIf.Name) then
					return nil
				end
			end
		end

		local Response = {
			Id = Choice.Text:gsub("%s+", "_"):lower(),
			Text = Choice.Response
		}

		if Choice.Choices then
			Response.Choices = {}
			for _, SubChoice in ipairs(Choice.Choices) do
				local Converted = ConvertChoice(SubChoice)
				if Converted then
					table.insert(Response.Choices, Converted)
				end
			end
		end

		return {
			Text = Choice.Text,
			Response = Response,
			Command = Choice.Action
		}
	end

	-- Add all dialog choices
	for _, Choice in ipairs(DIALOG_TREE) do
		local Converted = ConvertChoice(Choice)
		if Converted then
			table.insert(Choices, Converted)
		end
	end

	return {
		Id = "start",
		Text = GreetingText,
		Choices = Choices
	}
end