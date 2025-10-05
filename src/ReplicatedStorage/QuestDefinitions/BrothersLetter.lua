--!strict

local BrothersLetter = {
	Id = "BrothersLetter",
	Title = "Deliver a Letter",
	Description = "Brother Two asked you to deliver a letter to his brother",
	RequiresTurnIn = true,
	TurnInNpc = "BrotherOne",

	Objectives = {
		{
			Description = "Obtained letter",
			Type = "Deliver",
			TargetId = "Letter",
			RequiredAmount = 1
		}
	},

	Rewards = {
		Gold = 50,
		Experience = 25
	}
}

return BrothersLetter