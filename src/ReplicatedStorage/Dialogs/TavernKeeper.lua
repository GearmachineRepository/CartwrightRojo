--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))

return function(Player: Player)
	local Greeting = DialogBuilder.BuildGreeting("TavernKeeper", Player, {
		DefaultGreeting = "Welcome to the tavern, stranger!",
		ActiveQuestGreetings = {
			{QuestId = "FindRats", Greeting = "Any luck with those rats yet?"},
			{QuestId = "DeliverMessage", Greeting = "Did you deliver my message?"}
		},
		CompletedQuestGreetings = {
			{QuestId = "FindRats", Greeting = "Welcome back, rat hunter!"}
		},
		ReputationGreetings = {
			{Faction = "Tavern", MinRep = 100, Greeting = "Ah, my favorite customer! What can I do for you?"},
			{Faction = "Tavern", MinRep = 50, Greeting = "Good to see you again, friend!"}
		}
	})

	local Choices = {}

	DialogBuilder.AddQuestTurnIns(Choices, Player, {
		{
			QuestId = "FindRats",
			Text = "I cleared out the rats",
			ResponseText = "Excellent work! Here's your reward.",
			RewardText = "Received 50 gold and increased Tavern reputation!"
		},
		{
			QuestId = "DeliverMessage",
			Text = "I delivered your message",
			ResponseText = "Thank you! That was urgent."
		}
	})

	DialogBuilder.AddQuestOffers(Choices, Player, {
		{
			QuestId = "FindRats",
			OfferText = "I have a rat problem in my cellar. Can you help?",
			ButtonText = "Need any help?",
			QuestDescription = "Kill 10 rats in the cellar and I'll pay you well."
		},
		{
			QuestId = "SpecialDelivery",
			OfferText = "I have a special delivery job, but only for trusted folks.",
			ButtonText = "Any special work?",
			QuestDescription = "Deliver this rare package to the merchant across town.",
			RequireReputation = {Faction = "Tavern", MinAmount = 50}
		}
	})

	table.insert(Choices, {
		Text = "What do you sell?",
		Response = {
			Id = "shop",
			Text = "Take a look at my wares!",
			OpenGui = "TavernShopGui"
		}
	})

	table.insert(Choices, {
		Text = "Tell me about this town",
		Response = {
			Id = "lore",
			Text = "This town has a long history. The old temple dates back centuries...",
			Choices = {
				{
					Text = "Interesting, tell me more",
					Response = {
						Id = "more_lore",
						Text = "Legend says there's treasure hidden beneath the temple..."
					}
				},
				{
					Text = "Thanks for the info",
					Response = {
						Id = "lore_end",
						Text = "Anytime, traveler!"
					}
				}
			}
		}
	})

	table.insert(Choices, {
		Text = "Goodbye",
		Response = {
			Id = "goodbye",
			Text = "Come back anytime!"
		}
	})

	return {
		Id = "start",
		Text = Greeting,
		Choices = Choices
	}
end