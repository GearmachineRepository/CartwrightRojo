--!strict
--[[
	DIALOG & QUEST SYSTEM GUIDE
	Made for designers who want to create NPCs and quests!

	You only need to know TWO things:
	1. How to make Dialog files (NPC conversations)
	2. How to make Quest Definition files (quests players can do)

	Everything else is already set up for you!
]]

local Guide = {}

--[[
	═══════════════════════════════════════════════════════════════
	PART 1: WHERE TO PUT YOUR FILES
	═══════════════════════════════════════════════════════════════

	DIALOGS go here:
	ReplicatedStorage > Dialogs > YourNPCName.lua

	Example: If your NPC is named "Fisherman", create "Fisherman.lua"
	⚠️ The file name MUST match the NPC model's name exactly!

	QUESTS go here:
	ReplicatedStorage > QuestDefinitions > YourQuestName.lua

	Example: "FindTreasure.lua" or "KillRats.lua"
	⚠️ Use PascalCase (no spaces, capitalize each word)
]]

--[[
	═══════════════════════════════════════════════════════════════
	PART 2: MAKING A SIMPLE NPC (EASY MODE)
	═══════════════════════════════════════════════════════════════

	This is for NPCs who:
	- Give quests
	- Accept completed quests
	- Open shops
	- Have normal conversations

	Copy this template and change the words!
]]

Guide.SimpleNPCTemplate = [[
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))

return function(Player: Player)
	-- What the NPC says when you first talk to them
	local Greeting = DialogBuilder.BuildGreeting("NPCName", Player, {
		DefaultGreeting = "Hello, traveler!",

		-- If player has a quest active, say this instead
		ActiveQuestGreetings = {
			{QuestId = "MyQuest", Greeting = "How's that quest going?"}
		},

		-- If player finished a quest before, say this
		CompletedQuestGreetings = {
			{QuestId = "MyQuest", Greeting = "Good to see you again!"}
		}
	})

	local Choices = {}

	-- QUEST TURN-INS (when player finishes a quest)
	-- This automatically shows up when the quest is done!
	DialogBuilder.AddQuestTurnIns(Choices, Player, {
		{
			QuestId = "MyQuest",
			Text = "I finished your quest!",
			ResponseText = "Great job! Here's your reward."
		}
	})

	-- QUEST OFFERS (giving a quest to the player)
	-- This automatically shows up if they don't have the quest yet!
	DialogBuilder.AddQuestOffers(Choices, Player, {
		{
			QuestId = "MyQuest",
			OfferText = "I need help collecting flowers.",
			ButtonText = "Need any help?",
			QuestDescription = "Collect 10 red flowers for me please!"
		}
	})

	-- REGULAR DIALOG OPTIONS
	-- These always show up

	table.insert(Choices, {
		Text = "What do you sell?",
		Response = {
			Id = "shop",
			Text = "Check out my shop!",
			OpenGui = "MyShopGui"  -- Name of GUI in StarterGui
		}
	})

	table.insert(Choices, {
		Text = "Tell me a story",
		Response = {
			Id = "story",
			Text = "Once upon a time...",
			Choices = {
				{
					Text = "Cool story!",
					Response = {
						Id = "story_end",
						Text = "Thanks for listening!"
					}
				},
				{
					Text = "That's boring",
					Response = {
						Id = "story_boring",
						Text = "Well, excuse me!"
					}
				}
			}
		}
	})

	table.insert(Choices, {
		Text = "Goodbye",
		Response = {
			Id = "goodbye",
			Text = "See you later!"
		}
	})

	return {
		Id = "start",
		Text = Greeting,
		Choices = Choices
	}
end
]]

--[[
	═══════════════════════════════════════════════════════════════
	PART 3: MAKING QUESTS
	═══════════════════════════════════════════════════════════════

	Quests are the missions players can do!

	There are different TYPES of quest tasks:
	- Collect: Pick up items
	- Kill: Defeat enemies
	- TalkTo: Speak with NPCs
	- Interact: Click on objects
	- Deliver: Bring items to someone
]]

Guide.QuestTemplate = [[
--!strict

local MyQuest = {
	-- Quest info (change these!)
	Id = "MyQuest",
	Title = "Flower Gathering",
	Description = "Collect flowers for the shopkeeper",

	-- Does player need to return to NPC to finish?
	RequiresTurnIn = true,
	TurnInNpc = "Shopkeeper",  -- Who to return to

	-- What the player needs to do
	Objectives = {
		{
			Description = "Collect Red Flowers",
			Type = "Collect",  -- Type of task
			TargetId = "RedFlower",  -- Name of the item/enemy/npc
			RequiredAmount = 10  -- How many needed
		},
		{
			Description = "Collect Blue Flowers",
			Type = "Collect",
			TargetId = "BlueFlower",
			RequiredAmount = 5
		}
	},

	-- What player gets when done
	Rewards = {
		Gold = 100,
		Experience = 50
	}
}

return MyQuest
]]

--[[
	═══════════════════════════════════════════════════════════════
	QUEST TASK TYPES - WHAT PLAYERS CAN DO
	═══════════════════════════════════════════════════════════════

	COLLECT - Pick up items
	{
		Description = "Collect Apples",
		Type = "Collect",
		TargetId = "Apple",  -- Item name
		RequiredAmount = 10
	}

	KILL - Defeat enemies
	{
		Description = "Kill Goblins",
		Type = "Kill",
		TargetId = "Goblin",  -- Enemy name
		RequiredAmount = 5
	}

	TALKTO - Speak with NPCs
	{
		Description = "Talk to the Mayor",
		Type = "TalkTo",
		TargetId = "Mayor",  -- NPC name
		RequiredAmount = 1
	}

	INTERACT - Click on things
	{
		Description = "Open the Chest",
		Type = "Interact",
		TargetId = "TreasureChest",  -- Object name
		RequiredAmount = 1
	}

	DELIVER - Bring items to someone
	{
		Description = "Deliver Package",
		Type = "Deliver",
		TargetId = "Package",  -- Item name
		RequiredAmount = 1
	}
]]

--[[
	═══════════════════════════════════════════════════════════════
	PART 4: ADVANCED NPCs (HARD MODE)
	═══════════════════════════════════════════════════════════════

	For NPCs with:
	- Skill checks (like rolling dice)
	- Hidden dialog options
	- Memory (remembering past conversations)
	- Reputation requirements

	This is more complicated! Ask a programmer for help.
]]

Guide.AdvancedNPCTemplate = [[
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("AdvancedDialogBuilder"))

return function(Player: Player)
	local Choices = {}

	-- SKILL CHECK - Player rolls dice + their skill
	-- Only shows if they pass the roll!
	table.insert(Choices, DialogBuilder.CreateChoice(
		"[Persuasion] Convince him to help",
		{
			Id = "persuade_success",
			Text = "Fine, I'll help you.",
			SetFlags = {"ConvincedNPC"}  -- Remember this happened
		},
		{
			SkillCheck = {Skill = "Persuasion", Difficulty = 12}
		}
	))

	-- HIDDEN OPTION - Only shows if player passed persuasion before
	table.insert(Choices, DialogBuilder.CreateChoice(
		"Remember when you promised to help?",
		{
			Id = "remind",
			Text = "Oh right, I did say that..."
		},
		{
			Conditions = {
				{Type = "DialogFlag", Value = "ConvincedNPC"}
			}
		}
	))

	-- REPUTATION LOCKED - Only shows if player is friendly
	table.insert(Choices, DialogBuilder.CreateChoice(
		"Got any special work?",
		{
			Id = "special_quest",
			Text = "Actually, yes! But only for trusted folks.",
			GiveQuest = "SpecialMission"
		},
		{
			Conditions = {
				{Type = "HasReputation", Value = {Faction = "Town", Min = 50}}
			}
		}
	))

	-- ALWAYS VISIBLE - No conditions needed
	table.insert(Choices, {
		Text = "Goodbye",
		Response = {
			Id = "goodbye",
			Text = "See you around!"
		}
	})

	return {
		Id = "start",
		Text = "Hello there!",
		Choices = Choices
	}
end
]]

--[[
	═══════════════════════════════════════════════════════════════
	CONDITIONS - WHEN DIALOG OPTIONS APPEAR
	═══════════════════════════════════════════════════════════════

	HasQuest - Player has this quest active
	{Type = "HasQuest", Value = "QuestName"}

	CompletedQuest - Player finished this quest before
	{Type = "CompletedQuest", Value = "QuestName"}

	CanTurnInQuest - Quest is done, ready to turn in
	{Type = "CanTurnInQuest", Value = "QuestName"}

	HasReputation - Player is friendly with a faction
	{Type = "HasReputation", Value = {Faction = "Town", Min = 50}}

	Level - Player is high enough level
	{Type = "Level", Value = 10}

	HasItem - Player has an item in inventory
	{Type = "HasItem", Value = "Sword"}

	DialogFlag - Player saw something before (memory)
	{Type = "DialogFlag", Value = "MetKing"}

	HasSkill - Player has high enough skill
	{Type = "HasSkill", Value = {Skill = "Strength", Min = 15}}
]]

--[[
	═══════════════════════════════════════════════════════════════
	TIPS & TRICKS
	═══════════════════════════════════════════════════════════════

	✅ ALWAYS include a "Goodbye" option with no conditions
	   This prevents the dialog from getting stuck!

	✅ Test your dialogs by talking to the NPC multiple times
	   Make sure greetings change correctly

	✅ Quest file names should match the QuestId exactly
	   File: FindTreasure.lua → Id = "FindTreasure"

	✅ Dialog file names MUST match the NPC model name
	   NPC named "Bob" → File must be "Bob.lua"

	✅ Use simple quest names without spaces
	   Good: "FindTreasure", "KillRats"
	   Bad: "Find Treasure", "kill rats"

	⚠️ If dialog breaks, check the Output window for errors
	   It will tell you what went wrong!

	⚠️ Quest turn-ins only work if RequiresTurnIn = true
	   Set TurnInNpc to the NPC's name

	⚠️ Skill checks are random! Players might fail
	   Higher skill = better chance to pass
]]

--[[
	═══════════════════════════════════════════════════════════════
	NEED HELP?
	═══════════════════════════════════════════════════════════════

	1. Copy the templates above
	2. Change the text to what you want
	3. Save in the right folder
	4. Test in-game!

	If something breaks:
	- Check the Output window (View > Output)
	- Make sure file names match exactly
	- Ask a programmer for help with advanced features

	Common mistakes:
	- Dialog file name doesn't match NPC name
	- Forgot to add "Goodbye" option
	- Quest file name has spaces
	- Misspelled a QuestId
]]

return Guide