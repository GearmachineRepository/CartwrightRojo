local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))
local QuestManager = require(Modules:WaitForChild("QuestManager"))

return function(Player: Player)
	local HasCheckQuest = DialogBuilder.HasActiveQuest(Player, "CheckOnBrotherTwo")
	local HasLetterQuest = DialogBuilder.HasActiveQuest(Player, "BrothersLetter")
	local CompletedLetter = DialogBuilder.HasCompletedQuest(Player, "BrothersLetter")

	local Greeting = "Hello stranger!"
	if HasCheckQuest or HasLetterQuest or CompletedLetter then
		Greeting = "Welcome back!"
	end

	local Choices = {}

	if not CompletedLetter then
		table.insert(Choices, {
			Text = "How are you doing?",
			Response = {
				Id = "ask_how",
				Text = "I'm doing well, thanks for asking! My brother worries too much.",
				Choices = {
					{
						Text = "He'll be relieved to hear that",
						Response = {
							Id = "mention_letter",
							Text = "Actually, while you're here - could you take this letter back to him?",
							Choices = {
								{
									Text = "Of course, I'd be happy to",
									Response = {
										Id = "accept_letter",
										Text = "Thank you! Tell him I said hello."
									},
									Command = function(Plr: Player)
										if HasCheckQuest then
											QuestManager.UpdateQuestProgress(Plr, "CheckOnBrotherTwo", "TalkTo", "BrotherTwo", 1)
										end

										local Letter = game.ServerStorage.Items:FindFirstChild("Letter")
										if Letter then
											Letter:Clone().Parent = Plr.Backpack
										end

										if not HasLetterQuest then
											QuestManager.GiveQuest(Plr, "BrothersLetter")
										end

										QuestManager.UpdateQuestProgress(Plr, "BrothersLetter", "Deliver", "Letter", 1)
									end
								},
								{
									Text = "I'm kind of busy right now",
									Response = {
										Id = "decline_letter",
										Text = "No worries, maybe next time."
									}
								}
							}
						}
					}
				}
			},
			Command = function(Plr: Player)
				if HasCheckQuest then
					QuestManager.UpdateQuestProgress(Plr, "CheckOnBrotherTwo", "TalkTo", "BrotherTwo", 1)
				end
			end
		})
	end

	if HasLetterQuest then
		table.insert(Choices, {
			Text = "I'll make sure your brother gets the letter",
			Response = {
				Id = "already_has_letter",
				Text = "Thank you so much! I really appreciate it."
			}
		})
	end

	table.insert(Choices, {
		Text = "Just passing by",
		Response = {
			Id = "casual",
			Text = "Carry on!"
		}
	})

	table.insert(Choices, {
		Text = "Goodbye",
		Response = {
			Id = "goodbye",
			Text = "See you around!"
		}
	})

	return {
		Id = "start",
		Text = Greeting,
		Choices = Choices
	}
end