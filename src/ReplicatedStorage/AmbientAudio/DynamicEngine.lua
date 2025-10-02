--!strict
local Core  = require(script.Parent.Core)
local Utils = require(script.Parent.Utils)

local DynamicEngine = {}

-- public: foliage source registration
function DynamicEngine.Register(object: BasePart, soundType: string)
	if not object or not soundType or not Core.SoundLibrary[soundType] then return end
	for _, r in ipairs(Core.RegisteredObjects) do
		if r.Object == object then return end
	end
	table.insert(Core.RegisteredObjects, { Object=object, SoundType=soundType, LastSoundTime=0, Position=object.Position })
end

function DynamicEngine.Unregister(object: BasePart)
	for i=#Core.RegisteredObjects,1,-1 do
		if Core.RegisteredObjects[i].Object == object then table.remove(Core.RegisteredObjects, i) end
	end
end

local function destroy(sd)
	pcall(function() sd.Sound:Stop() end)
	if sd.SoundContainer and sd.SoundContainer.Parent then sd.SoundContainer:Destroy() end
end

local function create(soundType: string, pos: Vector3, src: BasePart?, isDyn: boolean)
	local cfg = Core.SoundLibrary[soundType]; if not cfg then return nil end
	local container = Utils.MakeContainer(pos)
	local att = Instance.new("Attachment"); att.Name="SoundAttachment"; att.Parent = container
	local snd = Utils.NewSound(cfg, Core.SoundGroup())
	snd.Parent = container
	return {
		Sound = snd, TargetVolume = cfg.Volume or 0, CurrentVolume = 0,
		Position = pos, SoundType = soundType, SourceObject = src,
		IsLooped = cfg.Looped or false, SoundContainer = container, Attachment = att, IsDynamic = isDyn,
	}
end

-- Schedulers
function DynamicEngine.ScheduleFoliage(playerPos: Vector3)
	local total = #Core.ActiveDynamics + #Core.ActiveTriggers
	local free = math.max(0, Core.MAX_CONCURRENT_SOUNDS - total)
	if free <= 0 then return end

	local foliage = 0
	for _, sd in ipairs(Core.ActiveDynamics) do if sd.SoundType ~= "WindGust" then foliage += 1 end end
	local need = math.min(Core.TARGET_DYNAMIC_SOUNDS - foliage, free)
	if need <= 0 then return end

	local now = tick()
	local cands = {}
	for i=#Core.RegisteredObjects,1,-1 do
		local ro = Core.RegisteredObjects[i]
		if not ro.Object or not ro.Object.Parent then
			table.remove(Core.RegisteredObjects, i)
		else
			ro.Position = ro.Object.Position
			local cfg = Core.SoundLibrary[ro.SoundType]
			if cfg then
				local d = Utils.Dist(ro.Position, playerPos)
				local inRange = d <= (cfg.Range or 0)
				local ok = true
				if Core.USE_TYPE_COOLDOWN and cfg.Cooldown then ok = (now - ro.LastSoundTime) >= cfg.Cooldown end
				if inRange and ok then table.insert(cands, ro) end
			end
		end
	end
	if #cands == 0 then return end
	table.sort(cands, function(a,b) return Utils.Dist(a.Position, playerPos) < Utils.Dist(b.Position, playerPos) end)

	local activeByType = {}
	for _, sd in ipairs(Core.ActiveDynamics) do activeByType[sd.SoundType] = (activeByType[sd.SoundType] or 0) + 1 end

	local byType = {}
	for _, ro in ipairs(cands) do
		byType[ro.SoundType] = byType[ro.SoundType] or {}
		table.insert(byType[ro.SoundType], ro)
	end

	local picked = {}
	while need > 0 do
		local choices = {}
		for st, list in pairs(byType) do
			if #list > 0 then table.insert(choices, {stype=st, count=activeByType[st] or 0}) end
		end
		if #choices == 0 then break end
		table.sort(choices, function(a,b)
			if a.count == b.count then
				local la, lb = byType[a.stype][1], byType[b.stype][1]
				return Utils.Dist(la.Position, playerPos) < Utils.Dist(lb.Position, playerPos)
			end
			return a.count < b.count
		end)
		local st = choices[1].stype
		local ro = table.remove(byType[st], 1)
		table.insert(picked, ro)
		activeByType[st] = (activeByType[st] or 0) + 1
		need -= 1
	end

	for _, ro in ipairs(picked) do
		local cfg = Core.SoundLibrary[ro.SoundType]
		local sd = create(ro.SoundType, ro.Position, ro.Object, true)
		if sd and cfg then
			sd.Sound:Play()
			local d = Utils.Dist(ro.Position, playerPos)
			sd.TargetVolume = Utils.CalcFade(d, cfg.Range, cfg.FadeDistance, cfg.Volume)
			table.insert(Core.ActiveDynamics, sd)
			ro.LastSoundTime = now
		end
	end
end

-- LocalGusts and BurstField spawns are driven directly during UpdateActive (they read TriggerZones).
local function spawnLocalGust(zone, playerPos: Vector3)
	local flow = Vector3.new(zone.Part:GetAttribute("FlowDirX") or 0, zone.Part:GetAttribute("FlowDirY") or 0, zone.Part:GetAttribute("FlowDirZ") or 0)
	if flow.Magnitude < 0.05 then
		flow = (workspace.GlobalWind.Magnitude > 0 and workspace.GlobalWind.Unit) or Vector3.new(1,0,0)
	end
	local spawn = (zone.EmitterMode == "CenterLine") and require(script.Parent.Utils).PosFromRodT(zone.Part, (math.random()*2-1))
		or require(script.Parent.Utils).RandomPointIn(zone.Part, playerPos, nil)
	local stype = zone.Part:GetAttribute("GustType") or "WindGust"
	local sd = create(stype, spawn, nil, true)
	if sd then
		sd.Sound:Play()
		sd._vel = flow.Unit * ((zone.Part:GetAttribute("GustSpeed") or Core.WindSpeedStudsPerSec) * (0.85 + math.random()*0.3))
		sd._deathTime = tick() + (1.8 + math.random()*1.0)
		table.insert(Core.ActiveDynamics, sd)
	end
end

local function spawnBurst(zone, playerPos: Vector3)
	local utils = require(script.Parent.Utils)
	local stype = zone.Part:GetAttribute("BurstType") or "Birds"
	local shell = zone.Part:GetAttribute("BurstShell") or 0
	local minSpace = zone.Part:GetAttribute("BurstMinSpacing") or 10
	local candidate = utils.RandomPointIn(zone.Part, playerPos, shell)
	if (candidate - playerPos).Magnitude < minSpace then return end
	local sd = create(stype, candidate, nil, true)
	if sd then
		sd.Sound:Play()
		sd._vel = Vector3.new((math.random()-0.5)*2, 0, (math.random()-0.5)*2) * 4
		sd._deathTime = tick() + (1.2 + math.random()*0.8)
		table.insert(Core.ActiveDynamics, sd)
	end
end

function DynamicEngine.UpdateActive(dt: number, playerPos: Vector3)
	-- Drive LocalGusts / BurstField per-zone
	for _, z in ipairs(Core.TriggerZones) do
		local d = (require(script.Parent.Utils).NearestPoint(z.Part, playerPos) - playerPos).Magnitude
		local inside = d <= z.EnterRadius

		if z.EmitterKind == "LocalGusts" and inside then
			z._gusts = z._gusts or {}
			z._gustAcc = (z._gustAcc or 0) + dt * (z.Part:GetAttribute("GustRate") or 0.4)
			local maxC = z.Part:GetAttribute("GustMax") or 2

			-- count current gusts owned by this zone
			local current = 0
			for _, sd in ipairs(Core.ActiveDynamics) do if sd.SoundType == (z.Part:GetAttribute("GustType") or "WindGust") then current += 1 end end

			while z._gustAcc >= 1 and current < maxC do
				z._gustAcc -= 1
				spawnLocalGust(z, playerPos)
				current += 1
			end
		elseif z.EmitterKind == "BurstField" and inside then
			z._burst = z._burst or {acc=0, actives={}}
			z._burst.acc += dt * (z.Part:GetAttribute("BurstRate") or 0.35)
			local maxC = z.Part:GetAttribute("BurstMax") or 3

			-- estimate current bursts (by type)
			local stype = z.Part:GetAttribute("BurstType") or "Birds"
			local current = 0
			for _, sd in ipairs(Core.ActiveDynamics) do if sd.SoundType == stype then current += 1 end end

			while z._burst.acc >= 1 and current < maxC do
				z._burst.acc -= 1
				spawnBurst(z, playerPos)
				current += 1
			end
		end
	end

	-- Update dynamics (fade/move/cull)
	for i = #Core.ActiveDynamics, 1, -1 do
		local sd = Core.ActiveDynamics[i]
		local cfg = Core.SoundLibrary[sd.SoundType]
		if not cfg then destroy(sd); table.remove(Core.ActiveDynamics, i); continue end

		if sd.SourceObject and sd.SourceObject.Parent then
			sd.Position = sd.SourceObject.Position
			if sd.SoundContainer then sd.SoundContainer.CFrame = CFrame.new(sd.Position) end
		end
		if sd._vel and sd.SoundContainer then
			sd.Position += sd._vel * dt
			sd.SoundContainer.CFrame = CFrame.new(sd.Position)
		end
		if sd._deathTime and tick() >= sd._deathTime then
			sd.TargetVolume = 0
		end

		if sd.SoundType ~= "WindBed" then
			local dist = require(script.Parent.Utils).Dist(sd.Position, playerPos)
			sd.TargetVolume = require(script.Parent.Utils).CalcFade(dist, cfg.Range or 0, cfg.FadeDistance or 0, cfg.Volume or 0)
			local tooFar = (cfg.Range ~= nil) and (dist > (cfg.Range + Core.OUT_OF_RANGE_BUFFER))
			local finished = (not sd.IsLooped) and (not sd.Sound.IsPlaying)
			if tooFar or finished then destroy(sd); table.remove(Core.ActiveDynamics, i); continue end
		end

		local diff = sd.TargetVolume - sd.CurrentVolume
		if math.abs(diff) > 0.001 then
			local dv = Core.SOUND_FADE_SPEED * dt
			sd.CurrentVolume = (diff > 0) and math.min(sd.TargetVolume, sd.CurrentVolume + dv)
				or math.max(sd.TargetVolume, sd.CurrentVolume - dv)
			sd.Sound.Volume = sd.CurrentVolume
		end
		if sd.CurrentVolume <= 0.001 and sd.TargetVolume <= 0.001 then
			destroy(sd); table.remove(Core.ActiveDynamics, i)
		end
	end
end

function DynamicEngine.DebugOneShot(soundType: string, pos: Vector3?)
	local p = pos or Vector3.new(0,10,0)
	local sd = create(soundType, p, nil, true)
	if sd then sd.Sound:Play(); table.insert(Core.ActiveDynamics, sd) end
end

function DynamicEngine.Cleanup()
	for _, sd in ipairs(Core.ActiveDynamics) do destroy(sd) end
	table.clear(Core.ActiveDynamics)
	table.clear(Core.RegisteredObjects)
end

return DynamicEngine