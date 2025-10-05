--[[
	═══════════════════════════════════════════════════════════════
	DIALOG HELPERS - QUICK REFERENCE
	═══════════════════════════════════════════════════════════════

	Use these helper functions instead of writing nested dialog tables!
	Just copy the example and change the text.

	HOW TO USE:
	1. Add at top of your dialog file:
	   local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))

	2. Use helpers to build your choices:
	   table.insert(Choices, DialogHelpers.BuildShopDialog({...}))

	3. Some helpers return functions - call them with Player:
	   local Choice = DialogHelpers.BuildRandomDialog({...})
	   table.insert(Choices, Choice(Player))
]]

local QuickReference = {}

--[[
	═══════════════════════════════════════════════════════════════
	1. BuildShopDialog
	Use for: Merchants, vendors
	═══════════════════════════════════════════════════════════════

	DialogHelpers.BuildShopDialog({
		ButtonText = "What do you sell?",
		IntroText = "I sell all sorts of goods!",
		GuiName = "GeneralStoreGui"  -- Name of GUI in StarterGui
	})
]]

--[[
	═══════════════════════════════════════════════════════════════
	2. BuildGiveItem
	Use for: Free item handouts, rewards, starter kits
	═══════════════════════════════════════════════════════════════

	DialogHelpers.BuildGiveItem({
		ButtonText = "Can I have a potion?",
		ResponseText = "Here you go!",
		ItemName = "HealthPotion",
		Amount = 1  -- Optional, defaults to 1
	})
]]

--[[
	═══════════════════════════════════════════════════════════════
	3. BuildInfoBranch
	Use for: Guards, townsfolk, info NPCs, Q&A
	═══════════════════════════════════════════════════════════════

	DialogHelpers.BuildInfoBranch({
		ButtonText = "Can I ask you something?",
		IntroText = "Of course! What would you like to know?",
		Questions = {
			{Question = "Where's the inn?", Answer = "Down the street."},
			{Question = "Any dangers?", Answer = "Watch for bandits."}
		},
		ExitText = "Thanks!"  -- Optional
	})
]]

--[[
	═══════════════════════════════════════════════════════════════
	4. BuildConversationChain
	Use for: Linear stories, lore, tutorials
	═══════════════════════════════════════════════════════════════

	DialogHelpers.BuildConversationChain({
		ButtonText = "Tell me a story",
		Chain = {
			{Player = "Tell me a story", NPC = "Long ago..."},
			{Player = "What happened?", NPC = "A hero arose..."},
			{Player = "Then what?", NPC = "He saved us all!"}
		},
		FinalText = "Wow!"  -- Optional
	})
]]

--[[
	═══════════════════════════════════════════════════════════════
	5. BuildTradeOffer
	Use for: Item exchanges, bartering
	═══════════════════════════════════════════════════════════════

	DialogHelpers.BuildTradeOffer({
		ButtonText = "Want to trade?",
		RequestText = "I'll give you a sword for 10 iron ore.",
		RequiredItem = "IronOre",
		RequiredAmount = 10,
		GiveItem = "RareSword",
		GiveAmount = 1,  -- Optional, defaults to 1
		SuccessText = "Deal! Here you go.",
		FailureText = "Come back when you have the items."
	})
]]

--[[
	═══════════════════════════════════════════════════════════════
	6. BuildMultiChoiceQuiz
	Use for: Riddles, passwords, knowledge checks
	═══════════════════════════════════════════════════════════════

	DialogHelpers.BuildMultiChoiceQuiz({
		ButtonText = "I know the answer",
		Question = "What's 2 + 2?",
		Choices = {
			{Text = "4", Correct = true, Response = "Correct!"},
			{Text = "5", Correct = false, Response = "Wrong!"},
			{Text = "3", Correct = false, Response = "Nope!"}
		},
		OnSuccess = function(Player)
			-- Give reward, unlock door, etc.
		end
	})
]]

--[[
	═══════════════════════════════════════════════════════════════
	7. BuildRandomDialog (RETURNS FUNCTION - CALL IT!)
	Use for: Ambient NPCs, repeated interactions, variety
	═══════════════════════════════════════════════════════════════

	local Choice = DialogHelpers.BuildRandomDialog({
		ButtonText = "How are you?",
		Responses = {
			"I'm great!",
			"Could be better.",
			"Just fine, thanks!",
			"Living the dream!"
		}
	})
	table.insert(Choices, Choice(Player))  -- ← IMPORTANT: Call with (Player)
]]

--[[
	═══════════════════════════════════════════════════════════════
	8. BuildSimpleGreeting
	Use for: Super simple ambient NPCs
	Returns a full dialog tree, not a choice!
	═══════════════════════════════════════════════════════════════

	-- Use as your entire dialog return:
	return DialogHelpers.BuildSimpleGreeting({
		Greetings = {
			"Hello!",
			"Good day!",
			"Nice weather!"
		},
		Farewells = {
			"Goodbye!",
			"See you!",
			"Take care!"
		}
	})
]]

--[[
	═══════════════════════════════════════════════════════════════
	9. BuildReputationGate (RETURNS FUNCTION - CALL IT!)
	Use for: Exclusive content for trusted players
	═══════════════════════════════════════════════════════════════

	local Choice = DialogHelpers.BuildReputationGate({
		Faction = "Town",
		MinRep = 50,
		ButtonText = "Got anything special?",
		LockedText = "Sorry, I don't know you well enough.",
		UnlockedContent = {
			Text = "For you? Of course!",
			Response = {
				Id = "special",
				Text = "Check out my exclusive items!",
				OpenGui = "SpecialShopGui"
			}
		}
	})
	table.insert(Choices, Choice(Player))  -- ← IMPORTANT: Call with (Player)
]]

--[[
	═══════════════════════════════════════════════════════════════
	COMPLETE EXAMPLE NPC - Simple Merchant
	═══════════════════════════════════════════════════════════════
]]

QuickReference.ExampleMerchant = [[
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))
local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))

return function(Player: Player)
	local Choices = {}

	-- Shop
	table.insert(Choices, DialogHelpers.BuildShopDialog({
		ButtonText = "What do you sell?",
		IntroText = "Take a look at my wares!",
		GuiName = "GeneralStoreGui"
	}))

	-- Free starter item
	table.insert(Choices, DialogHelpers.BuildGiveItem({
		ButtonText = "I'm new here",
		ResponseText = "Here's a starter potion. Good luck!",
		ItemName = "HealthPotion"
	}))

	-- Info
	table.insert(Choices, DialogHelpers.BuildInfoBranch({
		ButtonText = "Tell me about the area",
		IntroText = "What would you like to know?",
		Questions = {
			{Question = "Where's the inn?", Answer = "Down the main road."},
			{Question = "Any monsters nearby?", Answer = "Watch for wolves in the forest."}
		},
		ExitText = "Thanks"
	}))

	-- Goodbye
	table.insert(Choices, {
		Text = "Goodbye",
		Response = {Id = "bye", Text = "Come back soon!"}
	})

	return {
		Id = "start",
		Text = "Welcome to my shop!",
		Choices = Choices
	}
end
]]

--[[
	═══════════════════════════════════════════════════════════════
	COMPLETE EXAMPLE - Ambient Villager with Random Dialog
	═══════════════════════════════════════════════════════════════
]]

QuickReference.ExampleAmbientNPC = [[
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))

return function(Player: Player)
	local Choices = {}

	-- Random greeting
	local GreetChoice = DialogHelpers.BuildRandomDialog({
		ButtonText = "How's it going?",
		Responses = {
			"Doing great!",
			"Can't complain!",
			"Just another day.",
			"Living the dream!"
		}
	})
	table.insert(Choices, GreetChoice(Player))

	-- Random weather comment
	local WeatherChoice = DialogHelpers.BuildRandomDialog({
		ButtonText = "Nice weather, huh?",
		Responses = {
			"Beautiful day!",
			"Could be better.",
			"I've seen worse!",
			"Perfect weather for a walk."
		}
	})
	table.insert(Choices, WeatherChoice(Player))

	-- Goodbye
	table.insert(Choices, {
		Text = "See you later",
		Response = {Id = "bye", Text = "Take care!"}
	})

	return {
		Id = "start",
		Text = "Oh, hello there!",
		Choices = Choices
	}
end
]]

--[[
	═══════════════════════════════════════════════════════════════
	SUPER SIMPLE AMBIENT NPC (Just random greetings)
	═══════════════════════════════════════════════════════════════
]]

QuickReference.SuperSimpleNPC = [[
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))

return function(Player: Player)
	return DialogHelpers.BuildSimpleGreeting({
		Greetings = {
			"Hello!",
			"Good day!",
			"Nice to see you!",
			"How are you?"
		},
		Farewells = {
			"Goodbye!",
			"See you!",
			"Take care!",
			"Safe travels!"
		}
	})
end
]]

--[[
	═══════════════════════════════════════════════════════════════
	TIPS FOR YOUR MODELER
	═══════════════════════════════════════════════════════════════

	✅ Use helpers whenever possible - less typing, fewer errors

	✅ Mix helpers with manual dialog for complex interactions

	✅ Remember: Some helpers return FUNCTIONS
	   - BuildRandomDialog → Call with (Player)
	   - BuildReputationGate → Call with (Player)
	   - BuildFlagCheck → Call with (Player)

	✅ For super simple NPCs, use BuildSimpleGreeting as entire dialog

	✅ Combine multiple helpers in one NPC
	   Example: Shop + Info + Random greetings

	✅ If a helper doesn't fit, build dialog manually - that's fine!

	⚠️ Don't forget to add "Goodbye" option at the end

	⚠️ Item names must match exactly (case-sensitive!)

	⚠️ GuiName must match GUI in StarterGui exactly
]]

--[[
	═══════════════════════════════════════════════════════════════
	WHEN TO USE WHICH HELPER
	═══════════════════════════════════════════════════════════════

	NPC Type                    → Use This Helper
	─────────────────────────────────────────────────────────────
	Merchant/Vendor             → BuildShopDialog
	Quest Giver                 → DialogBuilder.BuildQuestOffer
	Info/Guard NPC              → BuildInfoBranch
	Storyteller/Elder           → BuildConversationChain
	Item Trader                 → BuildTradeOffer
	Gatekeeper/Riddler          → BuildMultiChoiceQuiz
	Ambient Villager            → BuildRandomDialog
	Super Simple Ambient        → BuildSimpleGreeting
	Exclusive Vendor            → BuildReputationGate
	Reward Giver                → BuildGiveItem

	═══════════════════════════════════════════════════════════════
	NEED MORE HELP?
	═══════════════════════════════════════════════════════════════

	Look at DialogHelpers_Examples.lua for complete working NPCs!

	Copy those examples and change the text to make your own NPCs.
]]

return QuickReference