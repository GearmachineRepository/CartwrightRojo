--!strict

local CheckOnBrotherTwo = {
	Id = "CheckOnBrotherTwo",
	Title = "Check on Brother Two",
	Description = "Brother One is worried. Go check on his brother near the marketplace.",
	RequiresTurnIn = false,

	Objectives = {
		{
			Description = "Check-in on Brother Two",
			Type = "TalkTo",
			TargetId = "BrotherTwo",
			RequiredAmount = 1
		}
	},

	Rewards = {
		Gold = 0,
		Experience = 0
	}
}

return CheckOnBrotherTwo