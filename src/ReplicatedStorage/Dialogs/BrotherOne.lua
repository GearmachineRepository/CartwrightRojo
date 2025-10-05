--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))

return function(Player: Player)
	local HasCheckQuest = DialogBuilder.HasActiveQuest(Player, "CheckOnBrotherTwo")
	local HasLetterQuest = DialogBuilder.HasActiveQuest(Player, "BrothersLetter")
	local CompletedCheck = DialogBuilder.HasCompletedQuest(Player, "CheckOnBrotherTwo")
	local CompletedLetter = DialogBuilder.HasCompletedQuest(Player, "BrothersLetter")

	local Greeting = "I haven't heard from my brother in ages."
	if HasCheckQuest or HasLetterQuest then
		Greeting = "Did you check on my brother yet?"
	elseif CompletedLetter then
		Greeting = "Thanks again for bringing me that letter!"
	elseif CompletedCheck then
		Greeting = "How's my brother?"
	end

	local Choices = {}

	DialogBuilder.AddQuestTurnIns(Choices, Player, {
		{
			QuestId = "BrothersLetter",
			Text = "I have the letter from your brother",
			ResponseText = "Thank you so much! Let me read it... He's doing well! Here's your reward."
		}
	})

	-- Use BuildQuestOffer for flexible quest offering
	if not HasCheckQuest and not CompletedCheck and not HasLetterQuest and not CompletedLetter then
		table.insert(Choices, DialogBuilder.BuildQuestOffer({
			QuestId = "CheckOnBrotherTwo",
			ButtonText = "Is everything alright?",
			IntroText = "Could you do me a favor? My brother lives across town and I haven't heard from him in weeks.",
			DetailText = "He usually visits every week, but I haven't seen him in a while. I'm worried something might have happened. Could you check on him?",
			LocationText = "He lives near the marketplace, in a small house with a blue door. You can't miss it.",
			AcceptText = "Thank you so much! Please let me know if he's okay.",
			DeclineText = "I understand. Please come back if you change your mind."
		}))
	end

	if CompletedCheck and not HasLetterQuest and not CompletedLetter then
		table.insert(Choices, {
			Text = "Your brother is doing good!",
			Response = {
				Id = "letter_check",
				Text = "Thank you. By any chance, did he mention a letter?",
				Choices = {
					{
						Text = "Not that I know of.",
						Response = {
							Id = "no_letter",
							Text = "Well, if you see him again, ask him about a letter."
						}
					},
					{
						Text = "Yeah, he did.",
						Response = {
							Id = "yes_letter",
							Text = "Well, if you see him again, could you bring back that letter?",
							Choices = {
								{
									Text = "Sure thing.",
									Response = {
										Id = "letter_commitment",
										Text = "Thank you."
									}
								}
							}
						}
					}
				}
			}
		})
	end

	table.insert(Choices, {
		Text = "Goodbye",
		Response = {
			Id = "goodbye",
			Text = "Take care!"
		}
	})

	return {
		Id = "start",
		Text = Greeting,
		Choices = Choices
	}
end