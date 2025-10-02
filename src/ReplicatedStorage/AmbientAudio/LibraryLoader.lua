--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Core  = require(script.Parent.Core)

local Loader = {}

function Loader.LoadSettings()
	local root = ReplicatedStorage:FindFirstChild("Ambience")
	local s = root and root:FindFirstChild("Settings")
	if not s then return end
	local function num(n, fb) local v = s:FindFirstChild(n) if v and v:IsA("NumberValue") then return v.Value end return fb end
	local function bool(n, fb) local v = s:FindFirstChild(n) if v and v:IsA("BoolValue") then return v.Value end return fb end

	Core.MAX_CONCURRENT_SOUNDS   = num("MaxConcurrentSounds", Core.MAX_CONCURRENT_SOUNDS)
	Core.TARGET_DYNAMIC_SOUNDS   = num("TargetDynamicSounds", Core.TARGET_DYNAMIC_SOUNDS)
	Core.DYNAMIC_SCHEDULER_INTERVAL = num("DynamicSchedulerInterval", Core.DYNAMIC_SCHEDULER_INTERVAL)
	Core.SOUND_FADE_SPEED        = num("SoundFadeSpeed", Core.SOUND_FADE_SPEED)
	Core.OUT_OF_RANGE_BUFFER     = num("OutOfRangeBuffer", Core.OUT_OF_RANGE_BUFFER)
	Core.TRIGGER_HYSTERESIS      = num("TriggerHysteresis", Core.TRIGGER_HYSTERESIS)
	Core.TRIGGER_EXIT_GRACE      = num("TriggerExitGrace", Core.TRIGGER_EXIT_GRACE)
	Core.USE_TYPE_COOLDOWN       = bool("UseTypeCooldown", Core.USE_TYPE_COOLDOWN)

	Core.WindEnabled             = bool("WindEnabled", Core.WindEnabled)
	Core.WindIntensity           = num("WindIntensity", Core.WindIntensity)
	Core.WindBedVolume           = num("WindBedVolume", Core.WindBedVolume)
	Core.WindGustTarget          = num("WindGustTarget", Core.WindGustTarget)
	Core.WindSpeedStudsPerSec    = num("WindSpeedStudsPerSec", Core.WindSpeedStudsPerSec)
end

function Loader.LoadSoundLibrary()
	local root = ReplicatedStorage:FindFirstChild("Ambience")
	local libRoot = root and root:FindFirstChild("SoundLibrary")
	if not libRoot then return end

	for _, typeFolder in ipairs(libRoot:GetChildren()) do
		if not typeFolder:IsA("Folder") then continue end
		local name = typeFolder.Name
		local cfg = Core.SoundLibrary[name] or {}

		local function num(n, fb) local v = typeFolder:FindFirstChild(n) if v and v:IsA("NumberValue") then return v.Value end return fb end
		local function bool(n, fb) local v = typeFolder:FindFirstChild(n) if v and v:IsA("BoolValue") then return v.Value end return fb end

		cfg.Volume = num("Volume", cfg.Volume or 0.25)
		cfg.Range = num("Range", cfg.Range or 120)
		cfg.FadeDistance = num("FadeDistance", cfg.FadeDistance or 30)
		cfg.MaxDistance = num("MaxDistance", cfg.MaxDistance or (cfg.Range or 100))
		cfg.MinDistance = num("MinDistance", cfg.MinDistance or 10)
		cfg.Looped = bool("Looped", cfg.Looped or false)
		cfg.Pitch = cfg.Pitch or {1.0, 1.0}

		cfg.SoundIds = {}
		local variants = typeFolder:FindFirstChild("Variants") or typeFolder
		for _, s in ipairs(variants:GetChildren()) do
			if s:IsA("Sound") and s.SoundId ~= "" then
				table.insert(cfg.SoundIds, s.SoundId)
			end
		end

		Core.SoundLibrary[name] = cfg
	end
end

return Loader