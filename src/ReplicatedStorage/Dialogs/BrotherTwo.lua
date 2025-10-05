--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))
local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))
local QuestManager = require(Modules:WaitForChild("QuestManager"))

return function(Player: Player)
	local HasCheckQuest = DialogBuilder.HasActiveQuest(Player, "CheckOnBrotherTwo")
	local HasLetterQuest = DialogBuilder.HasActiveQuest(Player, "BrothersLetter")
	local CompletedLetter = DialogBuilder.HasCompletedQuest(Player, "BrothersLetter")

	local Greeting = DialogHelpers.GetConditionalGreeting({

		{HasCheckQuest or HasLetterQuest or CompletedLetter, "Welcome back!"} -- If they have either quest or completed the letter quest

	}, "Hello stranger!") --> default greeting

	local Choices = {}

	if not CompletedLetter then --> Only show turn-in if they haven't completed the letter quest

		table.insert(Choices, DialogHelpers.CreateBranchingChoice(
			"How are you doing?", --> Player choice text
			"I'm doing well, thanks for asking! My brother worries too much.", --> NPC response text
			{

				DialogHelpers.CreateNestedChoice(
					"He'll be relieved to hear that", --> Player choice text
					"Actually, while you're here - could you take this letter back to him?", --> NPC response text
					{

						DialogHelpers.CreateSimpleChoice(
							"Of course, I'd be happy to", --> Player choice text
							"Thank you! Tell him I said hello.", --> NPC response text
							"accept_letter", --> Choice ID
							function(Plr: Player) --> Callback function when this choice is selected
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
						),

						DialogHelpers.CreateSimpleChoice(
							"I'm kind of busy right now", --> Player choice text
							"No worries, maybe next time.", --> NPC response text
							"decline_letter" --> Choice ID
						)
					},
					{

						DialogHelpers.CreateSimpleChoice(
							"Of course, I'd be happy to",
							"Thank you! Tell him I said hello.",
							"accept_letter",
							function(Plr: Player)
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
						),

						DialogHelpers.CreateSimpleChoice(
							"I'm kind of busy right now",
							"No worries, maybe next time.",
							"decline_letter"
						)
					},
					"mention_letter"
				)
			},
			"ask_how",
			function(Plr: Player)
				if HasCheckQuest then
					QuestManager.UpdateQuestProgress(Plr, "CheckOnBrotherTwo", "TalkTo", "BrotherTwo", 1)
				end
			end
		))
	end

	if HasLetterQuest then --> If they have the letter quest active
		table.insert(Choices, DialogHelpers.CreateSimpleChoice(
			"I'll make sure your brother gets the letter",
			"Thank you so much! I really appreciate it.",
			"already_has_letter"
		))
	end

	table.insert(Choices, DialogHelpers.CreateSimpleChoice("Just passing by", "Carry on!", "casual")) --> Casual choice
	table.insert(Choices, DialogHelpers.CreateSimpleChoice("Goodbye", "See you around!", "goodbye")) --> Goodbye choice

	return DialogHelpers.CreateDialogStart(Greeting, Choices)
end