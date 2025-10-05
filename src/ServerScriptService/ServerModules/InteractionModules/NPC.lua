--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local SoundPlayer = require(Modules:WaitForChild("SoundPlayer"))

local Events = ReplicatedStorage:WaitForChild("Events")
local DialogEvents = Events:WaitForChild("DialogEvents")
local StartDialogRemote = DialogEvents:WaitForChild("StartDialog") :: RemoteEvent
local StopDialogRemote = DialogEvents:WaitForChild("StopDialog") :: RemoteEvent

local NPC = {}

function NPC.StateAFunction(Player: Player, NpcModel: Instance, Config: any): ()
	if not NpcModel:IsA("Model") then return end

	if Config and Config.InteractionSound then
		SoundPlayer.PlaySound(Config.InteractionSound, NpcModel.PrimaryPart, {
			Volume = 0.4
		})
	end

	NpcModel:SetAttribute("CurrentState", "StateB")
	StartDialogRemote:FireClient(Player, NpcModel)
end

StopDialogRemote.OnServerEvent:Connect(function(Player: Player, NpcModel: Model)
	if NpcModel and NpcModel:IsA("Model") then
		NpcModel:SetAttribute("CurrentState", "StateA")
	end
end)

return NPC