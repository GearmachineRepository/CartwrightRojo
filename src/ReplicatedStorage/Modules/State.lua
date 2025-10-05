--!strict
local DialogModules = game.ReplicatedStorage:WaitForChild("Modules")
local Visuals = require(DialogModules:WaitForChild("Visuals"))

local State = {}

local SpeakingPlayers: {[Player]: boolean} = {}

function State.Start_Speak(Player: Player, UseBlur: boolean): ()
	if Player and Player:IsA("Player") then
		SpeakingPlayers[Player] = true
		Visuals.Show(Player.UserId, UseBlur)
	end
end

function State.End_Speak(Player: Player): ()
	if Player and Player:IsA("Player") then
		SpeakingPlayers[Player] = nil
		Visuals.Hide(Player.UserId)
	end
end

function State.Can_Speak(Player: Player): boolean
	return not SpeakingPlayers[Player]
end

return State