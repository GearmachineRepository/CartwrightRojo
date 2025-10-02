--!strict
local Utils = {}

local SoundInstances = workspace:FindFirstChild("SoundInstances")
if not SoundInstances then
	SoundInstances = Instance.new("Folder")
	SoundInstances.Name = "SoundInstances"
	SoundInstances.Parent = workspace
end

function Utils.Clamp(n: number, lo: number, hi: number): number
	return math.max(lo, math.min(hi, n))
end

function Utils.Dist(a: Vector3, b: Vector3): number
	return (a - b).Magnitude
end

function Utils.CalcFade(distance: number, range: number, fadeDist: number, baseVol: number): number
	if distance > range then return 0 end
	if fadeDist > 0 and distance > range - fadeDist then
		local t = (range - distance) / fadeDist
		return baseVol * Utils.Clamp(t, 0, 1)
	end
	return baseVol
end

function Utils.SmoothDampVector3(current: Vector3, target: Vector3, velocity: Vector3, smoothTime: number, maxSpeed: number?, dt: number)
	-- Unity-like critically-damped smoothing.
	-- smoothTime is time to reach ~63% of the way; 0.1–0.25 works well.
	local omega = 2 / math.max(1e-4, smoothTime)
	local x = omega * dt
	-- exp decay approximation that’s stable over variable dt
	local exp = 1 / (1 + x + 0.48*x*x + 0.235*x*x*x)

	local change = current - target
	local maxChange = (maxSpeed or math.huge) * smoothTime
	local changeMag = change.Magnitude
	if changeMag > maxChange then
		change = change * (maxChange / changeMag)
	end

	local temp = (velocity + change * omega) * dt
	local newVel = (velocity - temp * omega) * exp
	local newPos = target + (change + temp) * exp
	return newPos, newVel
end

function Utils.MakeContainer(pos: Vector3): BasePart
	local p = Instance.new("Part")
	p.Name = "SoundContainer"
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 1
	p.Size = Vector3.new(1,1,1)
	p.CFrame = CFrame.new(pos)
	p.Parent = SoundInstances
	return p
end

function Utils.NewSound(cfg: {[string]: any}, group: SoundGroup): Sound
	local s = Instance.new("Sound")
	s.SoundGroup = group
	s.Volume = 0
	s.RollOffMode = Enum.RollOffMode.InverseTapered
	s.EmitterSize = 8
	s.MaxDistance = cfg.MaxDistance or 100
	s.MinDistance = cfg.MinDistance or 10
	local ids: {string}? = cfg.SoundIds
	s.SoundId = (ids and #ids > 0 and ids[math.random(1, #ids)]) or ""
	if cfg.Pitch then
		s.Pitch = math.random(cfg.Pitch[1]*100, cfg.Pitch[2]*100)/100
	end
	s.Looped = cfg.Looped or false
	return s
end

-- channel id from attribute → model name → base partName
function Utils.ChannelIdFor(part: Instance): string?
	local attr = part:GetAttribute("ChannelId")
	if typeof(attr) == "string" and #attr > 0 then return attr end
	local a = part.Parent
	while a do
		if a:IsA("Model") then return a.Name end
		a = a.Parent
	end
	if part.Name then
		local base = string.split(part.Name, "_")[1]
		if base and #base > 0 then return base end
	end
	return nil
end

-- Rod helpers (box)
function Utils.ZoneRodInfo(part: BasePart): (CFrame, Vector3, number)
	local cf, sz = part.CFrame, part.Size
	local half = sz * 0.5
	local useX = half.X >= half.Z
	local axisDir = useX and cf.XVector or cf.ZVector
	local halfLen = useX and half.X or half.Z
	return cf, axisDir, halfLen
end

function Utils.RodTFor(part: BasePart, worldPos: Vector3): number
	local cf, axisDir, halfLen = Utils.ZoneRodInfo(part)
	local rel = worldPos - cf.Position
	local proj = rel:Dot(axisDir)
	return math.clamp(proj / math.max(halfLen, 1e-6), -1, 1)
end

function Utils.PosFromRodT(part: BasePart, t: number): Vector3
	local cf, axisDir, halfLen = Utils.ZoneRodInfo(part)
	return cf.Position + axisDir * (math.clamp(t, -1, 1) * halfLen)
end

function Utils.NearestPoint(part: BasePart, playerPos: Vector3): Vector3
	if part.Shape and part.Shape == Enum.PartType.Ball then
		local r = part.Size.X*0.5
		local c = part.Position
		local dir = playerPos - c
		local m = dir.Magnitude
		if m < 1e-3 then return c end
		return c + dir.Unit * math.min(r, m)
	end
	local cf, half = part.CFrame, part.Size * 0.5
	local lp = cf:PointToObjectSpace(playerPos)
	local clamped = Vector3.new(
		math.clamp(lp.X, -half.X, half.X),
		math.clamp(lp.Y, -half.Y, half.Y),
		math.clamp(lp.Z, -half.Z, half.Z)
	)
	return cf:PointToWorldSpace(clamped)
end

function Utils.RandomPointIn(part: BasePart, playerPos: Vector3?, shell: number?): Vector3
	if part.Shape and part.Shape == Enum.PartType.Ball then
		local r = part.Size.X*0.5
		if playerPos and shell and shell > 0 then
			local dir = (Vector3.new(math.random()-0.5, 0, math.random()-0.5)).Unit
			return part.Position + dir * math.min(shell, r)
		end
		local u,v,w = math.random(), math.random(), math.random()
		local theta = 2*math.pi*u
		local phi = math.acos(2*v - 1)
		local rr = r*(w^(1/3))
		return part.Position + Vector3.new(
			rr*math.sin(phi)*math.cos(theta),
			rr*math.cos(phi),
			rr*math.sin(phi)*math.sin(theta)
		)
	else
		local cf, half = part.CFrame, part.Size*0.5
		local x = math.random()*2-1
		local y = math.random()*2-1
		local z = math.random()*2-1
		return cf:PointToWorldSpace(Vector3.new(x*half.X, y*half.Y, z*half.Z))
	end
end

return Utils