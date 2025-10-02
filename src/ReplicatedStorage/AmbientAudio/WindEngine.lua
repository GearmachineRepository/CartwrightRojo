--!strict
local SoundService = game:GetService("SoundService")
local CollectionService = game:GetService("CollectionService")
local Core  = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)

local WindEngine = {}

local _bed: Sound? = nil
local _bedContainer: Instance? = nil
local _override: {Intensity: number?, Direction: Vector3?, BedVolume: number?, GustTarget: number?}? = nil

function WindEngine.BuildZones()
	table.clear(Core.WindZones)
	for _, p in ipairs(CollectionService:GetTagged("AmbientWindZone")) do
		if p:IsA("BasePart") then table.insert(Core.WindZones, p) end
	end
end

function WindEngine.InitBed()
	local cfg = Core.SoundLibrary.WindBed
	if not (cfg and Core.WindEnabled) then return end
	_bedContainer = Instance.new("Folder")
	_bedContainer.Name = "WindBedContainer"
	_bedContainer.Parent = SoundService
	_bed = Instance.new("Sound")
	_bed.SoundGroup = Core.SoundGroup()
	_bed.Looped = true
	_bed.Volume = 0
	local ids = cfg.SoundIds
	_bed.SoundId = (ids and ids[1]) or ""
	if cfg.Pitch then _bed.Pitch = math.random(cfg.Pitch[1]*100, cfg.Pitch[2]*100)/100 end
	_bed.Parent = _bedContainer
	_bed:Play()
end

function WindEngine.UpdateZoneOverride(playerPos: Vector3)
	local nearest, best
	for _, p in ipairs(Core.WindZones) do
		if p and p.Parent then
			local r = math.max(p.Size.X, p.Size.Y, p.Size.Z) * 0.5
			local d = Utils.Dist(p.Position, playerPos)
			if d <= r and (not best or d < best) then nearest, best = p, d end
		end
	end
	if nearest then
		_override = _override or {}
		local wi = nearest:GetAttribute("WindIntensity")
		local bv = nearest:GetAttribute("WindBedVolume")
		local gt = nearest:GetAttribute("WindGustTarget")
		local dx,dy,dz = nearest:GetAttribute("WindDirX"), nearest:GetAttribute("WindDirY"), nearest:GetAttribute("WindDirZ")
		if typeof(wi) == "number" then _override.Intensity = math.clamp(wi,0,1) end
		if typeof(bv) == "number" then _override.BedVolume = math.clamp(bv,0,1) end
		if typeof(gt) == "number" then _override.GustTarget = math.max(0,gt) end
		if typeof(dx) == "number" and typeof(dy) == "number" and typeof(dz) == "number" then
			local d = Vector3.new(dx,dy,dz); if d.Magnitude > 0.001 then _override.Direction = d.Unit end
		end
	else
		_override = nil
	end
end

function WindEngine.UpdateBed(dt: number)
	if not _bed or not Core.WindEnabled then return end
	local cfg = Core.SoundLibrary.WindBed
	local base = (cfg and cfg.Volume) or Core.WindBedVolume
	local inten = (_override and _override.Intensity) or Core.WindIntensity
	local bedBase = (_override and _override.BedVolume) or base
	local target = math.clamp(bedBase * inten, 0, 1)
	local diff = target - _bed.Volume
	if math.abs(diff) > 0.001 then
		local dv = Core.SOUND_FADE_SPEED * dt
		_bed.Volume = (diff > 0) and math.min(target, _bed.Volume + dv) or math.max(target, _bed.Volume - dv)
	end
end

local function effWind()
	local dir = (_override and _override.Direction) or (Core.WindDirection.Magnitude > 0 and Core.WindDirection.Unit or Vector3.new(1,0,0))
	local inten = (_override and _override.Intensity) or Core.WindIntensity
	local gustTarget = (_override and _override.GustTarget) or Core.WindGustTarget
	return dir, inten, gustTarget
end

function WindEngine.ScheduleGusts(playerPos: Vector3)
	if not Core.WindEnabled then return end
	local cfg = Core.SoundLibrary.WindGust; if not cfg then return end

	local total = #Core.ActiveDynamics + #Core.ActiveTriggers
	local free = math.max(0, Core.MAX_CONCURRENT_SOUNDS - total)
	if free <= 0 then return end

	local dir, inten, gustTarget = effWind()
	local desired = math.max(0, math.floor((gustTarget or 0) * inten + 0.5))
	if desired <= 0 then return end

	local gusts = 0
	for _, sd in ipairs(Core.ActiveDynamics) do if sd.SoundType == "WindGust" then gusts += 1 end end
	local slots = math.min(desired - gusts, free)
	if slots <= 0 then return end

	local right = Vector3.new(0,1,0):Cross(dir); if right.Magnitude < 1e-3 then right = Vector3.new(1,0,0) end
	right = right.Unit
	local radiusMin, radiusMax = 18, 36

	for _ = 1, slots do
		local lateral = right * (math.random()*(radiusMax-radiusMin) + radiusMin) * (math.random(0,1)==0 and -1 or 1)
		local spawnPos = playerPos - dir * radiusMax + lateral

		local container = Utils.MakeContainer(spawnPos)
		local att = Instance.new("Attachment"); att.Parent = container
		local snd = Utils.NewSound(cfg, Core.SoundGroup()); snd.Parent = container

		local sd = {
			Sound = snd, TargetVolume = cfg.Volume or 0, CurrentVolume = 0,
			Position = spawnPos, SoundType = "WindGust", SourceObject = nil,
			IsLooped = false, SoundContainer = container, Attachment = att, IsDynamic = true,
			_vel = dir * (Core.WindSpeedStudsPerSec * (0.85 + math.random()*0.3)),
			_deathTime = tick() + (2.2 + math.random()*1.0),
		}
		snd:Play()

		local d = Utils.Dist(spawnPos, playerPos)
		sd.TargetVolume = Utils.CalcFade(d, cfg.Range or 0, cfg.FadeDistance or 0, cfg.Volume or 0)

		table.insert(Core.ActiveDynamics, sd)
	end
end

function WindEngine.Cleanup()
	if _bed then pcall(function() _bed:Stop() end) end
	if _bedContainer and _bedContainer.Parent then _bedContainer:Destroy() end
	_bed, _bedContainer, _override = nil, nil, nil
end

return WindEngine