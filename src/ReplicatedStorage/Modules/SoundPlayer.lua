--!strict

local SoundService = game:GetService("SoundService")

local SoundPlayer = {}

local ActiveSounds: {[Sound]: boolean} = {}

function SoundPlayer.PlaySound(SoundId: string, Parent: Instance?, Config: {
	Volume: number?,
	SoundGroup: string?,
	PlaybackSpeed: number?,
	RollOffMaxDistance: number?,
	RollOffMinDistance: number?,
	RollOffMode: Enum.RollOffMode?
}?): Sound?
	if not SoundId or SoundId == "" then
		return nil
	end

	local NewSound = Instance.new("Sound")
	NewSound.RollOffMode = (Config and Config.RollOffMode) or Enum.RollOffMode.Linear
	NewSound.RollOffMaxDistance = (Config and Config.RollOffMaxDistance) or 75
	NewSound.RollOffMinDistance = (Config and Config.RollOffMinDistance) or 5
	NewSound.SoundId = SoundId
	NewSound.Volume = (Config and Config.Volume) or 0.5
	NewSound.PlaybackSpeed = (Config and Config.PlaybackSpeed) or 1
	NewSound.Parent = Parent or SoundService

	if Config and Config.SoundGroup then
		local SoundGroup = SoundService:FindFirstChild(Config.SoundGroup)
		if SoundGroup and SoundGroup:IsA("SoundGroup") then
			NewSound.SoundGroup = SoundGroup
		end
	else
		local DefaultGroup = SoundService:FindFirstChild("Sound Effects")
		if DefaultGroup and DefaultGroup:IsA("SoundGroup") then
			NewSound.SoundGroup = DefaultGroup
		end
	end

	ActiveSounds[NewSound] = true

	NewSound:Play()

	NewSound.Ended:Connect(function()
		ActiveSounds[NewSound] = nil
		NewSound:Destroy()
	end)

	return NewSound
end

function SoundPlayer.StopSound(Sound: Sound): ()
	if not Sound or not Sound.Parent then
		return
	end

	ActiveSounds[Sound] = nil
	Sound:Stop()
	Sound:Destroy()
end

function SoundPlayer.StopAllSounds(): ()
	local SoundsToStop = {}
	for Sound, _ in pairs(ActiveSounds) do
		table.insert(SoundsToStop, Sound)
	end

	for _, Sound in pairs(SoundsToStop) do
		SoundPlayer.StopSound(Sound)
	end
end

return SoundPlayer