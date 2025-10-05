--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local SoundPlayer = require(Modules:WaitForChild("SoundPlayer"))
local DialogHandler = require(Modules:WaitForChild("DialogHandler"))

local Events = ReplicatedStorage:WaitForChild("Events")
local DialogEvents = Events:WaitForChild("DialogEvents")
local StartDialogRemote = DialogEvents:WaitForChild("StartDialog") :: RemoteEvent
local StopDialogRemote = DialogEvents:WaitForChild("StopDialog") :: RemoteEvent

local NPC = {}

local PlayerCooldowns: {[Player]: number} = {}
local INTERACTION_COOLDOWN = 1.0

local function SetNpcCooldown(Player: Player, _: Player, ToggleDelay: boolean?): ()
	local CooldownKey = "DialogCooldown"
	Player:SetAttribute(CooldownKey, true)

	if ToggleDelay then
		task.delay(INTERACTION_COOLDOWN, function()
			Player:SetAttribute(CooldownKey, nil)
		end)
	end
end

function NPC.StateAFunction(Player: Player, NpcModel: Instance, Config: any): ()
	if not NpcModel:IsA("Model") then return end

	local CurrentTime = tick()
	local LastInteraction = PlayerCooldowns[Player] or 0

	if CurrentTime - LastInteraction < INTERACTION_COOLDOWN then
		return
	end

	if Player:GetAttribute("DialogCooldown") then
		return
	end

	if Config and Config.InteractionSound then
		SoundPlayer.PlaySound(Config.InteractionSound, NpcModel.PrimaryPart, {
			Volume = 0.4
		})
	end

	NpcModel:SetAttribute("CurrentState", "StateB")

	StartDialogRemote:FireClient(Player, NpcModel)

	DialogHandler.Start(NpcModel, Player, function()
		NpcModel:SetAttribute("CurrentState", "StateA")
		PlayerCooldowns[Player] = tick()
		SetNpcCooldown(Player, Player)
	end)
end

StopDialogRemote.OnServerEvent:Connect(function(Player: Player, NpcModel: Model)
	if NpcModel and NpcModel:IsA("Model") then
		NpcModel:SetAttribute("CurrentState", "StateA")
		DialogHandler.EndDialog(Player)
		PlayerCooldowns[Player] = tick()
		SetNpcCooldown(Player, Player, true)
	end
end)

return NPC