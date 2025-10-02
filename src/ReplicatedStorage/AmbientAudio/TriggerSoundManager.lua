--!strict

local Core = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)
local TriggerTypes = require(script.Parent.TriggerTypes)

type SoundData = TriggerTypes.SoundData
type TriggerZone = TriggerTypes.TriggerZone

local TriggerSoundManager = {}

-- Destroy a sound data instance
local function DestroySoundData(SoundData: SoundData): ()
	pcall(function() 
		SoundData.Sound:Stop() 
	end)
	if SoundData.SoundContainer and SoundData.SoundContainer.Parent then 
		SoundData.SoundContainer:Destroy() 
	end
end

-- Create a new sound for a trigger zone
function TriggerSoundManager.CreateSound(SoundType: string, Position: Vector3, SourcePart: BasePart?): SoundData?
	local Config = Core.SoundLibrary[SoundType]
	if not Config then return nil end

	local Container = Utils.MakeContainer(Position)
	local Attachment = Instance.new("Attachment")
	Attachment.Name = "SoundAttachment"
	Attachment.Parent = Container

	local Sound = Utils.NewSound(Config, Core.SoundGroup())
	Sound.Parent = Container

	return {
		Sound = Sound,
		TargetVolume = Config.Volume or 0,
		CurrentVolume = 0,
		Position = Position,
		SoundType = SoundType,
		SourceObject = SourcePart,
		IsLooped = Config.Looped or false,
		SoundContainer = Container,
		Attachment = Attachment,
		IsDynamic = false,
	}
end

-- Ensure we have capacity for a new trigger sound by evicting dynamics if needed
function TriggerSoundManager.EnsureCapacityForTrigger(): ()
	local Total = #Core.ActiveDynamics + #Core.ActiveTriggers
	if Total < Core.MAX_CONCURRENT_SOUNDS then return end

	-- Evict farthest dynamic (except WindGust)
	local Players = game:GetService("Players")
	local LocalPlayer = Players.LocalPlayer
	local HumanoidRootPart = LocalPlayer and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then return end

	local FarthestIndex, FarthestDistance
	for Index, SoundData in ipairs(Core.ActiveDynamics) do
		if SoundData.SoundType ~= "WindGust" then
			local Distance = (SoundData.Position - HumanoidRootPart.Position).Magnitude
			if not FarthestDistance or Distance > FarthestDistance then
				FarthestDistance = Distance
				FarthestIndex = Index
			end
		end
	end

	if FarthestIndex then
		DestroySoundData(Core.ActiveDynamics[FarthestIndex])
		table.remove(Core.ActiveDynamics, FarthestIndex)
	end
end

-- Update volumes for all active trigger sounds and clean up finished ones
function TriggerSoundManager.CommitVolumes(DeltaTime: number): ()
	for Index = #Core.ActiveTriggers, 1, -1 do
		local SoundData : TriggerTypes.SoundData = Core.ActiveTriggers[Index] :: {[any]: any}
		local VolumeDifference = SoundData.TargetVolume - SoundData.CurrentVolume

		if math.abs(VolumeDifference) > 0.001 then
			local VolumeChange = Core.SOUND_FADE_SPEED * DeltaTime
			SoundData.CurrentVolume = if VolumeDifference > 0 
				then math.min(SoundData.TargetVolume, SoundData.CurrentVolume + VolumeChange)
				else math.max(SoundData.TargetVolume, SoundData.CurrentVolume - VolumeChange)
			SoundData.Sound.Volume = SoundData.CurrentVolume
		end

		if SoundData.CurrentVolume <= 0.001 and SoundData.TargetVolume <= 0.001 then
			DestroySoundData(SoundData)
			table.remove(Core.ActiveTriggers, Index)
		end
	end
end

-- Clean up all trigger sounds
function TriggerSoundManager.Cleanup(): ()
	for _, SoundData in ipairs(Core.ActiveTriggers) do 
		DestroySoundData(SoundData) 
	end
	table.clear(Core.ActiveTriggers)
end

return TriggerSoundManager