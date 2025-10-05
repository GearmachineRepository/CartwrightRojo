--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(Modules:WaitForChild("QuestManager"))

local MerchantConversation = function(Player: Player)
	local HasFlowerQuest = QuestManager.HasActiveQuest(Player, "GatherFlowers")
	local CompletedFlowerQuest = QuestManager.HasCompletedQuest(Player, "GatherFlowers")

	if HasFlowerQuest then
		local Quest = QuestManager.GetActiveQuest(Player, "GatherFlowers")
		local BlueFlowerProgress = Quest.Objectives[1].CurrentAmount
		local RedFlowerProgress = Quest.Objectives[2].CurrentAmount

		return {
			Text = "How goes the flower gathering? I need " .. tostring(5 - BlueFlowerProgress) .. " more blue and " .. tostring(3 - RedFlowerProgress) .. " more red.",
			Animation = "Thinking",
			Choices = {
				{
					Text = "Still working on it",
					Response = {
						Text = "Take your time. The flowers bloom best in the morning light.",
						Animation = "Happy"
					}
				},
				{
					Text = "Where can I find them?",
					Response = {
						Text = "Blue flowers grow near water. Red ones prefer the sunny meadows.",
						Animation = "Thinking"
					}
				}
			}
		}
	end

	if CompletedFlowerQuest then
		return {
			Text = "Welcome back, flower gatherer!",
			Animation = "Wave",
			Choices = {
				{
					Text = "What's for sale?",
					Response = {
						Text = "Take a look at my wares!",
						Animation = "Happy",
						OpenShop = "GeneralStore"
					}
				},
				{
					Text = "Goodbye",
					Response = {
						Text = "Come back anytime!",
						Animation = "Wave",
						EndConversation = true
					}
				}
			}
		}
	end

	return {
		Text = "Welcome to my shop! Looking for supplies?",
		Animation = "Wave",
		Choices = {
			{
				Text = "What do you sell?",
				Response = {
					Text = "I have potions and various supplies. Take a look!",
					Animation = "Happy",
					OpenShop = "GeneralStore"
				}
			},
			{
				Text = "Do you need any help?",
				Response = {
					Text = "Actually, yes! I need flowers for my potions. Could you gather some for me?",
					Animation = "Thinking",
					Choices = {
						{
							Text = "What kind of flowers?",
							Response = {
								Text = "I need 5 blue flowers and 3 red flowers. I'll pay you well!",
								Animation = "Happy",
								Choices = {
									{
										Text = "I'll do it",
										Response = {
											Text = "Wonderful! Return when you have them all.",
											Animation = "Happy",
											OnComplete = function(Plr: Player)
												QuestManager.GiveQuest(Plr, "GatherFlowers")
											end,
											EndConversation = true
										}
									},
									{
										Text = "Not right now",
										Response = {
											Text = "No problem. The offer stands if you change your mind.",
											Animation = "Thinking",
											EndConversation = true
										}
									}
								}
							}
						}
					}
				}
			},
			{
				Text = "Just browsing",
				Response = {
					Text = "Feel free to look around!",
					Animation = "Happy",
					EndConversation = true
				}
			}
		}
	}
end

return MerchantConversation