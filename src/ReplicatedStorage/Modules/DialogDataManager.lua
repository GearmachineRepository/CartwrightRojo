--!strict
local DialogDataManager = {}

local Players = game:GetService("Players")

export type PlayerDialogData = {
	CompletedSkillChecks: {[string]: boolean},
	DialogFlags: {[string]: boolean},
	LastNpcInteractions: {[string]: number}
}

local PlayerData: {[Player]: PlayerDialogData} = {}

local _: PlayerDialogData = { -- Default Data
	CompletedSkillChecks = {},
	DialogFlags = {},
	LastNpcInteractions = {}
}

function DialogDataManager.InitializePlayer(Player: Player): ()
	if PlayerData[Player] then
		return
	end

	PlayerData[Player] = {
		CompletedSkillChecks = {},
		DialogFlags = {},
		LastNpcInteractions = {}
	}
end

function DialogDataManager.GetPlayerData(Player: Player): PlayerDialogData?
	return PlayerData[Player]
end

function DialogDataManager.HasCompletedSkillCheck(Player: Player, SkillCheckId: string): boolean
	local Data = PlayerData[Player]
	if not Data then
		return false
	end

	return Data.CompletedSkillChecks[SkillCheckId] == true
end

function DialogDataManager.SetSkillCheckCompleted(Player: Player, SkillCheckId: string): ()
	local Data = PlayerData[Player]
	if not Data then
		DialogDataManager.InitializePlayer(Player)
		Data = PlayerData[Player]
	end

	if Data then
		Data.CompletedSkillChecks[SkillCheckId] = true
	end
end

function DialogDataManager.HasDialogFlag(Player: Player, FlagName: string): boolean
	local Data = PlayerData[Player]
	if not Data then
		return false
	end

	return Data.DialogFlags[FlagName] == true
end

function DialogDataManager.SetDialogFlag(Player: Player, FlagName: string, Value: boolean): ()
	local Data = PlayerData[Player]
	if not Data then
		DialogDataManager.InitializePlayer(Player)
		Data = PlayerData[Player]
	end

	if Data then
		Data.DialogFlags[FlagName] = Value
	end
end

function DialogDataManager.GetLastNpcInteraction(Player: Player, NpcName: string): number?
	local Data = PlayerData[Player]
	if not Data then
		return nil
	end

	return Data.LastNpcInteractions[NpcName]
end

function DialogDataManager.SetLastNpcInteraction(Player: Player, NpcName: string, Timestamp: number): ()
	local Data = PlayerData[Player]
	if not Data then
		DialogDataManager.InitializePlayer(Player)
		Data = PlayerData[Player]
	end

	if Data then
		Data.LastNpcInteractions[NpcName] = Timestamp
	end
end

function DialogDataManager.ClearPlayerData(Player: Player): ()
	PlayerData[Player] = nil
end

Players.PlayerAdded:Connect(function(Player: Player)
	DialogDataManager.InitializePlayer(Player)
end)

Players.PlayerRemoving:Connect(function(Player: Player)
	DialogDataManager.ClearPlayerData(Player)
end)

return DialogDataManager