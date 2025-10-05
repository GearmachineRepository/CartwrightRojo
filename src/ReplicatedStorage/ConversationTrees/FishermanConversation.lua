--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(Modules:WaitForChild("QuestManager"))

local FishermanConversation = function(Player: Player)
	local HasTreasureQuest = QuestManager.HasActiveQuest(Player, "FindTreasure")
	local CompletedTreasureQuest = QuestManager.HasCompletedQuest(Player, "FindTreasure")

	if HasTreasureQuest then
		return {
			Text = "Found any treasure yet?",
			Animation = "Thinking",
			Choices = {
				{
					Text = "Still searching the depths",
					Response = {
						Text = "The tides will guide you. Look near the old shipwreck.",
						Animation = "Happy"
					}
				},
				{
					Text = "This is too hard",
					Response = {
						Text = "The sea rewards the patient. Don't give up!",
						Animation = "Thinking"
					}
				}
			}
		}
	end

	if CompletedTreasureQuest then
		return {
			Text = "Ah, the treasure hunter returns!",
			Animation = "Happy",
			Choices = {
				{
					Text = "Any more work?",
					Response = {
						Text = "Not at the moment. The sea is calm today.",
						Animation = "Thinking"
					}
				},
				{
					Text = "Just passing by",
					Response = {
						Text = "May the tides be ever in your favour!",
						Animation = "Happy",
						EndConversation = true
					}
				}
			}
		}
	end

	return {
		Text = "May the tides be in your favour!",
		Animation = "Happy",
		Choices = {
			{
				Text = "Who are you?",
				Response = {
					Text = "I am the fisherman! I've sailed these waters for decades.",
					Animation = "Happy",
					Choices = {
						{
							Text = "I need help finding something",
							Response = {
								Text = "Treasure, is it? Many search. Few return with more than barnacles. But you look determined.",
								Animation = "Thinking",
								Choices = {
									{
										Text = "I'll take the challenge",
										Response = {
											Text = "Brave soul! Find me a treasure chest from the depths and I'll reward you handsomely.",
											Animation = "Happy",
											OnComplete = function(Plr: Player)
												QuestManager.GiveQuest(Plr, "FindTreasure")
											end,
											EndConversation = true
										}
									},
									{
										Text = "Maybe another time",
										Response = {
											Text = "The sea will still be here when you're ready.",
											Animation = "Thinking",
											EndConversation = true
										}
									}
								}
							}
						},
						{
							Text = "Just exploring",
							Response = {
								Text = "Then keep your fins light and your eyes open. Danger lurks in deep waters.",
								Animation = "Thinking",
								EndConversation = true
							}
						}
					}
				}
			},
			{
				Text = "Do you sell anything?",
				Response = {
					Text = "Aye, I have some fishing supplies if you're interested.",
					Animation = "Happy",
					OpenShop = "FishingSupplies"
				}
			},
			{
				Text = "Just passing through",
				Response = {
					Text = "Then may your journey be smooth as sea glass.",
					Animation = "Happy",
					EndConversation = true
				}
			}
		}
	}
end

return FishermanConversation