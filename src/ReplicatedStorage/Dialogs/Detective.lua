--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local DialogBuilder = require(Modules:WaitForChild("AdvancedDialogBuilder"))
local DialogConditions = require(Modules:WaitForChild("DialogConditions"))

return function(Player: Player)
	local IntroNode = {
		Id = "intro",
		Text = "A grizzled detective looks up from his notes. His eyes are weary but sharp.",
		SetFlags = {"MetDetective"},
		Choices = {
			DialogBuilder.CreateChoice(
				"I need information about the murder.",
				{
					Id = "murder_info",
					Text = "What do you know about the victim?",
					Choices = {
						DialogBuilder.CreateChoice(
							"[Perception] Notice something off about his story",
							{
								Id = "perception_success",
								Text = "His eyes dart to the left. He's hiding something.",
								SetFlags = {"DetectiveLying"}
							},
							{
								SkillCheck = {Skill = "Perception", Difficulty = 12}
							}
						),
						DialogBuilder.CreateChoice(
							"Thanks for the information",
							{
								Id = "end_murder_talk",
								Text = "Good luck with your investigation."
							}
						)
					}
				},
				{
					Conditions = {
						{Type = "HasQuest", Value = "MurderInvestigation"}
					}
				}
			),

			DialogBuilder.CreateChoice(
				"[Authority] You WILL answer my questions.",
				{
					Id = "authority_success",
					Text = "The detective straightens up, intimidated. 'Fine, fine. What do you want to know?'",
					SetFlags = {"IntimidatedDetective"}
				},
				{
					SkillCheck = {Skill = "Authority", Difficulty = 14}
				}
			),

			DialogBuilder.CreateChoice(
				"[Empathy] You look troubled. Want to talk about it?",
				{
					Id = "empathy_success",
					Text = "He sighs deeply. 'It's this case... it reminds me of my daughter.'",
					Choices = {
						DialogBuilder.CreateChoice(
							"Tell me about your daughter",
							{
								Id = "daughter_story",
								Text = "Years ago, she went missing. Never found her. That's why I became a detective.",
								SetFlags = {"LearnedDaughterStory"}
							}
						),
						DialogBuilder.CreateChoice(
							"I'm sorry to hear that",
							{
								Id = "condolences",
								Text = "Thank you. Not many people understand."
							}
						)
					}
				},
				{
					SkillCheck = {Skill = "Empathy", Difficulty = 10}
				}
			),

			DialogBuilder.CreateChoice(
				"I heard you knew the victim personally",
				{
					Id = "personal_connection",
					Text = "His face goes pale. 'Where did you hear that?'",
					Choices = {
						DialogBuilder.CreateChoice(
							"[Logic] Piece together the evidence",
							{
								Id = "logic_deduction",
								Text = "The photographs in his office, the letter in the victim's pocket... You were partners.",
								SetFlags = {"SolvedConnection"}
							},
							{
								SkillCheck = {Skill = "Logic", Difficulty = 16}
							}
						),
						DialogBuilder.CreateChoice(
							"Just a hunch",
							{
								Id = "hunch",
								Text = "He relaxes slightly. 'You're fishing. I didn't know him.'"
							}
						)
					}
				},
				{
					Conditions = {
						{Type = "DialogFlag", Value = "DetectiveLying"}
					}
				}
			),

			DialogBuilder.CreateChoice(
				"About your daughter...",
				{
					Id = "daughter_followup",
					Text = "His expression softens. 'You remembered.'",
					Choices = {
						DialogBuilder.CreateChoice(
							"[Suggest] Maybe I can help find her",
							{
								Id = "offer_help",
								Text = "Really? After all these years... I'd be grateful.",
								GiveQuest = "FindDaughter"
							},
							{
								Conditions = {
									{Type = "HasReputation", Value = {Faction = "Police", Min = 50}}
								}
							}
						),
						DialogBuilder.CreateChoice(
							"I hope you find her someday",
							{
								Id = "daughter_hope",
								Text = "Thank you. That means a lot."
							}
						),
						DialogBuilder.CreateChoice(
							"I should go",
							{
								Id = "leave_daughter_talk",
								Text = "Of course. Take care."
							}
						)
					}
				},
				{
					Conditions = {
						{Type = "DialogFlag", Value = "LearnedDaughterStory"}
					}
				}
			),

			DialogBuilder.CreateChoice(
				"I solved the case!",
				{
					Id = "case_solved",
					Text = "You did? Show me what you've found.",
					TurnInQuest = "MurderInvestigation"
				},
				{
					Conditions = {
						{Type = "CanTurnInQuest", Value = "MurderInvestigation"}
					}
				}
			),

			DialogBuilder.CreateChoice(
				"Goodbye",
				{
					Id = "goodbye",
					Text = "Stay safe out there."
				}
			)
		}
	}

	local GreetAgainNode = {
		Id = "greet_again",
		Text = "The detective nods in recognition. 'Back again?'",
		Choices = IntroNode.Choices
	}

	local HasMet = DialogConditions.Check(Player, {Type = "DialogFlag", Value = "MetDetective"})

	return DialogBuilder.ProcessNode(Player, HasMet and GreetAgainNode or IntroNode)
end