--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))

return function(Player: Player)
	local Greeting = DialogBuilder.BuildGreeting("Fisherman", Player, {
		DefaultGreeting = "May the tides be in your favour!",
		ActiveQuestGreetings = {
			{QuestId = "FindTreasure", Greeting = "How goes the treasure hunt? The depths can be treacherous!"}
		},
		CompletedQuestGreetings = {
			{QuestId = "FindTreasure", Greeting = "Ah, the treasure hunter returns! Well done on that haul."}
		}
	})

	local Choices = {}

	DialogBuilder.AddQuestTurnIns(Choices, Player, {
		{
			QuestId = "FindTreasure",
			Text = "I found the treasure chest!",
			ResponseText = "Incredible work! The sea rewards the brave. Here's your payment.",
			RewardText = "You received 100 gold and 200 experience!"
		}
	})

	DialogBuilder.AddQuestOffers(Choices, Player, {
		{
			QuestId = "FindTreasure",
			OfferText = "I need a brave soul to search the ocean depths for treasure. Many search. Few return with more than barnacles.",
			ButtonText = "Need any help?",
			QuestDescription = "Find me a treasure chest from the ocean depths and I'll reward you handsomely."
		}
	})

	table.insert(Choices, {
		Text = "Do you sell fishing supplies?",
		Response = {
			Id = "shop",
			Text = "Aye, I've got rods, bait, and other gear. Take a look!",
			OpenGui = "FishingShopGui"
		}
	})

	table.insert(Choices, {
		Text = "Tell me about the waters here",
		Response = {
			Id = "lore",
			Text = "These waters hold many secrets. The old shipwreck lies beyond the reef, where the light barely reaches.",
			Choices = {
				{
					Text = "Any advice for diving?",
					Response = {
						Id = "diving_advice",
						Text = "Watch the currents, and never dive alone. The sea can be unforgiving."
					}
				},
				{
					Text = "Thanks for the tip",
					Response = {
						Id = "lore_end",
						Text = "Anytime, sailor. May your nets be full!"
					}
				}
			}
		}
	})

	table.insert(Choices, {
		Text = "Just passing through",
		Response = {
			Id = "goodbye",
			Text = "Then may your journey be smooth as sea glass."
		}
	})

	return {
		Id = "start",
		Text = Greeting,
		Choices = Choices
	}
end