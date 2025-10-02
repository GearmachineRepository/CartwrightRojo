--!strict
local SoundService = game:GetService("SoundService")
local AmbienceGroup = SoundService:WaitForChild("Ambience")

local Core = {}

-- Config (defaults; overridable by folders or SetConfiguration)
Core.MAX_CONCURRENT_SOUNDS = 8
Core.TARGET_DYNAMIC_SOUNDS = 4
Core.DYNAMIC_SCHEDULER_INTERVAL = 0.25
Core.SOUND_FADE_SPEED = 10
Core.OUT_OF_RANGE_BUFFER = 50
Core.TRIGGER_HYSTERESIS = 4.0
Core.TRIGGER_EXIT_GRACE = 0.35
Core.USE_TYPE_COOLDOWN = true

Core.WindEnabled = true
Core.WindIntensity = 0.55
Core.WindDirection = Vector3.new(1,0,0)
Core.WindGustTarget = 1
Core.WindBedVolume = 0.08
Core.WindSpeedStudsPerSec = 22

-- State
Core.SoundLibrary = {
	-- preserve your IDs/entries; can be overridden by LibraryLoader
	TreeRustling = { SoundIds = { "rbxassetid://9114518779","rbxassetid://9114518395","rbxassetid://9114519223", "rbxassetid://9080200077" }, Volume=0.25, Pitch={0.8,1.2}, Cooldown=8, Range=150, MaxDistance=100, MinDistance=10, FadeDistance=30 },
	GrassRustle   = { SoundIds = { "rbxassetid://9114518233","rbxassetid://9114518560" }, Volume=0.2,  Pitch={0.9,1.3}, Cooldown=5, Range=120, MaxDistance=80, MinDistance=8, FadeDistance=25 },
	BushMovement  = { SoundIds = { "rbxassetid://9114519078","rbxassetid://9114518577" }, Volume=0.22, Pitch={0.85,1.15},Cooldown=6, Range=130, MaxDistance=90, MinDistance=12, FadeDistance=28 },

	WaterFlowing  = { SoundIds = { "rbxassetid://104045199928352" }, Volume=0.4,  Pitch={1.0,1.0}, Looped=true, Range=130, MaxDistance=200, MinDistance=15, FadeDistance=50 },
	FireCrackling = { SoundIds = { "rbxassetid://109494611784143" }, Volume=0.35, Pitch={0.9,1.1}, Looped=true, Range=100, MaxDistance=160, MinDistance=8,  FadeDistance=40 },

	River         = { SoundIds = { "rbxassetid://4975689439" }, Volume=0.32, Pitch={0.98,1.02}, Looped=true, Range=140, MaxDistance=220, MinDistance=12, FadeDistance=55 },
	
	WindChimes    = { SoundIds = { "rbxassetid://9120749869"}, Volume=0.25, Pitch={0.95,1.05}, Looped=true, Range=140, MaxDistance=220, MinDistance=12, FadeDistance=55 },

	WindBed       = { SoundIds = { "rbxassetid://5799870105" }, Volume=0.125, Pitch={0.98,1.02}, Looped=true },
	WindGust      = { SoundIds = { "rbxassetid://9119679789" }, Volume=0.25, Pitch={0.95,1.05}, Range=60, FadeDistance=25, MaxDistance=90, MinDistance=8, Cooldown=3 },

	Birds         = { SoundIds = { "rbxassetid://9080200077" }, Volume=0.22, Pitch={0.95,1.05}, Range=90, FadeDistance=30, MaxDistance=110, MinDistance=8 },
	Frogs         = { SoundIds = { "rbxassetid://9114871640" }, Volume=0.22, Pitch={0.98,1.}, Range=90, FadeDistance=30, MaxDistance=110, MinDistance=8 },
	
	Decay         = { SoundIds = { "rbxassetid://9043347008" }, Volume=0.45, Pitch={1,1}, Looped=true, Range=90, FadeDistance=30, MaxDistance=110, MinDistance=8 }, 
}

-- Data structs
Core.RegisteredObjects = {}      -- foliage: { Object, SoundType, LastSoundTime, Position }
Core.ActiveDynamics = {}         -- one-shots + foliage SoundData
Core.ActiveTriggers = {}         -- looping trigger SoundData
Core.TriggerZones = {}           -- TriggerZone records
Core.WindZones = {}              -- wind override zones

-- Channels (looped sounds with handoff)
Core.ChannelState = {}           -- [ChannelId] = { ActiveSound, CurrentZone }

Core._accum = 0
Core.SoundUpdateCounter = 0

-- Shared accessors
function Core.SoundGroup(): SoundGroup
	return AmbienceGroup
end

-- Stats
function Core.Stats()
	local byDyn = {}
	for _, sd in ipairs(Core.ActiveDynamics) do
		byDyn[sd.SoundType] = (byDyn[sd.SoundType] or 0) + 1
	end
	local byTrig = {}
	for _, sd in ipairs(Core.ActiveTriggers) do
		byTrig[sd.SoundType] = (byTrig[sd.SoundType] or 0) + 1
	end
	local gusts = byDyn["WindGust"] or 0
	local foliage = 0
	for k,v in pairs(byDyn) do if k ~= "WindGust" then foliage += v end end
	return {
		ActiveTotal = #Core.ActiveDynamics + #Core.ActiveTriggers,
		ActiveTriggers = #Core.ActiveTriggers,
		ActiveDynamics = #Core.ActiveDynamics,
		ActiveFoliage = foliage,
		ActiveWindGusts = gusts,
		TargetDynamicFoliage = Core.TARGET_DYNAMIC_SOUNDS,
		TriggerZones = #Core.TriggerZones,
		RegisteredObjects = #Core.RegisteredObjects,
		BreakdownDynamics = byDyn,
		BreakdownTriggers = byTrig,
		UpdateCounter = Core.SoundUpdateCounter,
	}
end

function Core.ApplyConfig(cfg: {[string]: any})
	if cfg.MaxConcurrentSounds then Core.MAX_CONCURRENT_SOUNDS = cfg.MaxConcurrentSounds end
	if cfg.TargetDynamicSounds then Core.TARGET_DYNAMIC_SOUNDS = cfg.TargetDynamicSounds end
	if cfg.DynamicSchedulerInterval then Core.DYNAMIC_SCHEDULER_INTERVAL = cfg.DynamicSchedulerInterval end
	if cfg.SoundFadeSpeed then Core.SOUND_FADE_SPEED = cfg.SoundFadeSpeed end
	if cfg.OutOfRangeBuffer then Core.OUT_OF_RANGE_BUFFER = cfg.OutOfRangeBuffer end
	if cfg.TriggerHysteresis then Core.TRIGGER_HYSTERESIS = cfg.TriggerHysteresis end
	if cfg.TriggerExitGrace then Core.TRIGGER_EXIT_GRACE = cfg.TriggerExitGrace end
	if cfg.UseTypeCooldown ~= nil then Core.USE_TYPE_COOLDOWN = cfg.UseTypeCooldown end

	if cfg.WindEnabled ~= nil then Core.WindEnabled = cfg.WindEnabled end
	if typeof(cfg.WindIntensity) == "number" then Core.WindIntensity = math.clamp(cfg.WindIntensity,0,1) end
	if typeof(cfg.WindBedVolume) == "number" then Core.WindBedVolume = math.clamp(cfg.WindBedVolume,0,1) end
	if typeof(cfg.WindGustTarget) == "number" then Core.WindGustTarget = math.max(0, cfg.WindGustTarget) end
	if typeof(cfg.WindSpeedStudsPerSec) == "number" then Core.WindSpeedStudsPerSec = math.max(0, cfg.WindSpeedStudsPerSec) end
	if typeof(cfg.WindDirX) == "number" and typeof(cfg.WindDirY) == "number" and typeof(cfg.WindDirZ) == "number" then
		local d = Vector3.new(cfg.WindDirX, cfg.WindDirY, cfg.WindDirZ)
		if d.Magnitude > 0.001 then Core.WindDirection = d.Unit end
	end
end

function Core.Reset()
	table.clear(Core.RegisteredObjects)
	table.clear(Core.ActiveDynamics)
	table.clear(Core.ActiveTriggers)
	table.clear(Core.TriggerZones)
	table.clear(Core.WindZones)
	table.clear(Core.ChannelState)
	Core._accum = 0
end

return Core