--!strict

local CollectionService = game:GetService("CollectionService")
local Core = require(script.Parent.Core)
local TriggerTypes = require(script.Parent.TriggerTypes)

type TriggerZone = TriggerTypes.TriggerZone

local TriggerZoneBuilder = {}

-- Build all trigger zones from CollectionService tags
function TriggerZoneBuilder.BuildZones(): {TriggerZone}
	local Zones: {TriggerZone} = {}

	for _, Part in ipairs(CollectionService:GetTagged("AmbientSoundTrigger")) do
		if not Part:IsA("BasePart") then continue end

		local SoundType = Part:GetAttribute("SoundType") or "River"
		if not Core.SoundLibrary[SoundType] then continue end

		local EmitterKind = Part:GetAttribute("EmitterKind") or "Loop"
		local Volume = Part:GetAttribute("Volume") or Core.SoundLibrary[SoundType].Volume or 0.5
		local FadeDistance = Part:GetAttribute("FadeDistance") or Core.SoundLibrary[SoundType].FadeDistance or 20
		local Radius = math.max(Part.Size.X, Part.Size.Y, Part.Size.Z) * 0.5
		local Mode = Part:GetAttribute("EmitterMode")
		local EmitterMode = Mode or ((Part.Shape and Part.Shape == Enum.PartType.Ball) and "NearestPoint" or "CenterLine")

		local RawChannelId = Part:GetAttribute("ChannelId")
		local ChannelId = (typeof(RawChannelId) == "string" and #RawChannelId > 0) and RawChannelId or nil

		table.insert(Zones, {
			Part = Part,
			SoundType = SoundType,
			EmitterMode = EmitterMode,
			EmitterKind = EmitterKind,
			EnterRadius = Radius,
			ExitRadius = Radius + Core.TRIGGER_HYSTERESIS,
			FadeDistance = FadeDistance,
			Volume = Volume,
			ChannelId = ChannelId,
			RodT = nil,
			LastRodUpdate = 0,
			State = "OUT",
			ActiveSound = nil,
			_exitTimer = 0,
			_gusts = nil,
			_gustAcc = 0,
			_burst = {acc = 0, actives = {}},
		})
	end

	return Zones
end

return TriggerZoneBuilder