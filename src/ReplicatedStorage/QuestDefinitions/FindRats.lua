--!strict

local FindRats = {
	Id = "FindRats",
	Title = "Rat Problem",
	Description = "Clear out the rats in the tavern cellar",
	RequiresTurnIn = true,
	TurnInNpc = "TavernKeeper",
	Objectives = {
		{
			Description = "Kill Rats",
			Type = "Kill",
			TargetId = "Rat",
			RequiredAmount = 10
		}
	},
	Rewards = {
		Gold = 50,
		Experience = 100,
		Reputation = {
			Faction = "Tavern",
			Amount = 10
		}
	}
}

return FindRats