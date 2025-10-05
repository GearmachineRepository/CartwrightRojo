--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local AdvancedDialogBuilder = require(Modules:WaitForChild("AdvancedDialogBuilder"))
local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))
local DialogConditions = require(Modules:WaitForChild("DialogConditions"))
local QuestManager = require(Modules:WaitForChild("QuestManager"))

return function(Player: Player)
	local HasMet = DialogConditions.Check(Player, {Type = "DialogFlag", Value = "MetDetective"})

	local Greeting = DialogHelpers.GetConditionalGreeting({
		{HasMet, "The detective nods in recognition. \"Back again?\""}
	}, "A grizzled detective looks up from his notes. His eyes are weary but sharp.")

	local Choices = {}

	-- Murder investigation path (quest-gated)
	table.insert(Choices, DialogHelpers.Advanced.CreateConditionalChoice({
		ButtonText = "I need information about the murder.",
		ResponseText = "\"What do you know about the victim?\"",
		Conditions = {
			{Type = "HasQuest", Value = "MurderInvestigation"}
		},
		SubChoices = {
			DialogHelpers.Advanced.CreateSkillCheck({
				Skill = "Perception",
				Difficulty = 12,
				ButtonText = "Notice something off about his story",
				SuccessResponse = "His eyes dart to the left. He's hiding something.",
				SuccessFlags = {"DetectiveLying"},
				FailureResponse = "You watch him carefully, but nothing seems out of the ordinary."
			}),

			DialogHelpers.CreateSimpleChoice(
				"Thanks for the information",
				"\"Good luck with your investigation.\"",
				"end_murder_talk"
			)
		}
	}))

	-- Authority intimidation check
	table.insert(Choices, DialogHelpers.Advanced.CreateSkillCheck({
		Skill = "Authority",
		Difficulty = 14,
		ButtonText = "You WILL answer my questions.",
		SuccessResponse = "The detective straightens up, intimidated. \"Fine, fine. What do you want to know?\"",
		SuccessFlags = {"IntimidatedDetective"},
		FailureResponse = "He glares at you. \"I don't respond well to threats. Get out of my office.\""
	}))

	-- Empathy emotional connection
	table.insert(Choices, DialogHelpers.Advanced.CreateSkillCheck({
		Skill = "Empathy",
		Difficulty = 10,
		ButtonText = "You look troubled. Want to talk about it?",
		SuccessResponse = "He sighs deeply. \"It's this case... it reminds me of my daughter.\"",
		SuccessChoices = {
			DialogHelpers.CreateSimpleChoice(
				"Tell me about your daughter",
				"\"Years ago, she went missing. Never found her. That's why I became a detective.\"",
				"daughter_story",
				function(Plr: Player)
					DialogConditions.SetFlag(Plr, "LearnedDaughterStory", true)
				end
			),

			DialogHelpers.CreateSimpleChoice(
				"I'm sorry to hear that",
				"\"Thank you. Not many people understand.\"",
				"condolences"
			)
		},
		FailureResponse = "He glances at you briefly. \"I'm fine. Just thinking about the case.\""
	}))

	-- Logic deduction (flag-gated)
	table.insert(Choices, DialogHelpers.Advanced.CreateFlagGatedChoice({
		ButtonText = "I heard you knew the victim personally",
		ResponseText = "His face goes pale. \"Where did you hear that?\"",
		RequiredFlag = "DetectiveLying",
		SubChoices = {
			DialogHelpers.Advanced.CreateSkillCheck({
				Skill = "Logic",
				Difficulty = 16,
				ButtonText = "Piece together the evidence",
				SuccessResponse = "\"The photographs in his office, the letter in the victim's pocket... You were partners.\"",
				SuccessFlags = {"SolvedConnection"},
				FailureResponse = "You try to connect the dots, but the evidence doesn't quite add up in your mind."
			}),

			DialogHelpers.CreateSimpleChoice(
				"Just a hunch",
				"He relaxes slightly. \"You're fishing. I didn't know him.\"",
				"hunch"
			)
		}
	}))

	-- Daughter follow-up (flag-gated)
	table.insert(Choices, DialogHelpers.Advanced.CreateFlagGatedChoice({
		ButtonText = "About your daughter...",
		ResponseText = "His expression softens. \"You remembered.\"",
		RequiredFlag = "LearnedDaughterStory",
		SubChoices = {
			DialogHelpers.Advanced.CreateReputationGatedChoice({
				ButtonText = "Maybe I can help find her",
				ResponseText = "\"Really? After all these years... I'd be grateful.\"",
				Faction = "Police",
				MinRep = 50,
				Command = function(Plr: Player)
					QuestManager.GiveQuest(Plr, "FindDaughter")
				end
			}),

			DialogHelpers.CreateSimpleChoice(
				"I hope you find her someday",
				"\"Thank you. That means a lot.\"",
				"daughter_hope"
			),

			DialogHelpers.CreateSimpleChoice(
				"I should go",
				"\"Of course. Take care.\"",
				"leave_daughter_talk"
			)
		}
	}))

	-- Quest turn-in
	table.insert(Choices, DialogHelpers.Advanced.CreateQuestGatedChoice({
		ButtonText = "I solved the case!",
		ResponseText = "\"You did? Show me what you've found.\"",
		RequiredQuest = "MurderInvestigation",
		CanTurnIn = true,
		Command = function(Plr: Player)
			QuestManager.TurnInQuest(Plr, "MurderInvestigation")
		end
	}))

	-- Goodbye
	table.insert(Choices, DialogHelpers.CreateSimpleChoice(
		"Goodbye",
		"\"Stay safe out there.\"",
		"goodbye"
	))

	local DialogTree = DialogHelpers.CreateDialogStart(Greeting, Choices)

	if not HasMet then
		DialogConditions.SetFlag(Player, "MetDetective", true)
	end

	warn(DialogTree)
	return AdvancedDialogBuilder.ProcessNode(Player, DialogTree)
end