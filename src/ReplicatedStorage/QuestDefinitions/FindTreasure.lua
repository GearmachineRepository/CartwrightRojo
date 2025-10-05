--!strict

local FindTreasure = {
	Id = "FindTreasure",
	Title = "Treasure Hunt",
	Description = "Find a treasure chest from the ocean depths and bring it to the fisherman",
	RequiresTurnIn = true,
	TurnInNpc = "Fisherman",
	Objectives = {
		{
			Description = "Find Treasure Chest",
			Type = "Deliver",
			TargetId = "Treasure Chest",
			RequiredAmount = 1,
			Trackable = true
		}
	},
	Rewards = {
		Gold = 100,
		Experience = 200
	}
}

return FindTreasure