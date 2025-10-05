--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("DialogBuilder"))
local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))

return function(Player: Player)
	local HasCheckQuest = DialogBuilder.HasActiveQuest(Player, "CheckOnBrotherTwo")
	local HasLetterQuest = DialogBuilder.HasActiveQuest(Player, "BrothersLetter")
	local CompletedCheck = DialogBuilder.HasCompletedQuest(Player, "CheckOnBrotherTwo")
	local CompletedLetter = DialogBuilder.HasCompletedQuest(Player, "BrothersLetter")

	local Greeting = DialogHelpers.GetConditionalGreeting({
		{HasCheckQuest or HasLetterQuest, "Did you check on my brother yet?"},
		{CompletedLetter, "Thanks again for bringing me that letter!"},
		{CompletedCheck, "How's my brother?"}
	}, "I haven't heard from my brother in ages.")

	local Choices = {}

	DialogBuilder.AddQuestTurnIns(Choices, Player, {
		{
			QuestId = "BrothersLetter",
			Text = "I have the letter from your brother",
			ResponseText = "Thank you so much! Let me read it... He's doing well! Here's your reward."
		}
	})

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
		table.insert(Choices, DialogHelpers.CreateBranchingChoice(
			"Your brother is doing good!",
			"Thank you. By any chance, did he mention a letter?",
			{
				DialogHelpers.CreateSimpleChoice(
					"Not that I know of.",
					"Well, if you see him again, ask him about a letter.",
					"no_letter"
				),
				DialogHelpers.CreateNestedChoice(
					"Yeah, he did.",
					"Well, if you see him again, could you bring back that letter?",
					{
						DialogHelpers.CreateSimpleChoice(
							"Sure thing.",
							"Thank you.",
							"letter_commitment"
						)
					},
					"yes_letter"
				)
			},
			"letter_check"
		))
	end

	table.insert(Choices, DialogHelpers.CreateSimpleChoice("Goodbye", "Take care!", "goodbye"))

	return DialogHelpers.CreateDialogStart(Greeting, Choices)
end