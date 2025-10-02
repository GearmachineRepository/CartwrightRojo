local folder = script.Parent:WaitForChild("Wagon"):WaitForChild("PlacementGrid"):WaitForChild("WagonStorage")
assert(folder and folder:IsA("Folder"), "Select an Area Folder containing the cell BaseParts")

-- --- Collect cells (ignore the optional Origin part)
local cells = {}
for _, ch in ipairs(folder:GetDescendants()) do
	if ch:IsA("BasePart") and ch.Name ~= "Origin" then
		table.insert(cells, ch)
	end
end
assert(#cells > 0, ("No BaseParts found under folder '%s'"):format(folder:GetFullName()))

-- --- Choose frame (Origin CFrame if provided, else from first cell)
local originPart = folder:FindFirstChild("Origin")
local baseCF
local useOrigin = false
if originPart and originPart:IsA("BasePart") then
	baseCF = originPart.CFrame
	useOrigin = true
else
	-- Infer a frame from first cell: X = Right, Y = Up, Z = -Look
	-- We'll use U = X axis, V = -Z axis to mimic a top-down shelf by default.
	local p = cells[1]
	baseCF = p.CFrame
end

-- Build axis basis: U for columns (X), V for rows (Y). We use Right and -Look so a typical Part
-- facing forward (LookVector) makes rows increase "downwards" when seen from the front.
local U = baseCF.RightVector
local V = -baseCF.LookVector
local O = baseCF.Position

-- Helper: project a world point into (u,v) in the base frame
local function toUV(pos: Vector3)
	local rel = baseCF:PointToObjectSpace(pos)
	return rel.X, -rel.Z -- X ~ along Right (U), -Z ~ along -Look (V)
end

-- Gather all (u,v) coords
local uv = table.create(#cells)
for i, c in ipairs(cells) do
	local u, v = toUV(c.Position)
	uv[i] = {u = u, v = v, part = c}
end

-- Infer grid step sizes du, dv by looking at sorted coordinate deltas (robust to noise)
local function inferStep(vals: {number})
	table.sort(vals)
	local deltas = {}
	for i = 2, #vals do
		local d = math.abs(vals[i] - vals[i-1])
		if d > 1e-3 then table.insert(deltas, d) end
	end
	if #deltas == 0 then return 1 end
	table.sort(deltas)
	-- use median of the smallest third to avoid outliers
	local k = math.max(1, math.floor(#deltas/3))
	local acc = 0
	for i = 1, k do acc += deltas[i] end
	return acc / k
end

local us, vs = {}, {}
for i = 1, #uv do us[i] = uv[i].u; vs[i] = uv[i].v end
local du = inferStep(us)
local dv = inferStep(vs)

-- If an Origin exists and you want to override step manually, put NumberValues "CellW"/"CellH" under Origin
local cw = originPart and originPart:FindFirstChild("CellW")
local ch = originPart and originPart:FindFirstChild("CellH")
if cw and cw:IsA("NumberValue") and cw.Value > 0 then du = cw.Value end
if ch and ch:IsA("NumberValue") and ch.Value > 0 then dv = ch.Value end

-- Normalize so (0,0) is at the minimum u/v corner unless an Origin is present.
-- With an Origin, we keep its object-space zero as (0,0).
local u0, v0
if useOrigin then
	u0, v0 = 0, 0
else
	u0, v0 = math.huge, math.huge
	for _, t in ipairs(uv) do
		if t.u < u0 then u0 = t.u end
		if t.v < v0 then v0 = t.v end
	end
end

-- Round helper with tolerance
local function iround(x)
	return math.floor(x + 0.5)
end

-- Assign indices
local maxX, maxY = -math.huge, -math.huge
for _, t in ipairs(uv) do
	local gx = iround((t.u - u0) / du)
	local gy = iround((t.v - v0) / dv)
	t.part:SetAttribute("GridX", gx)
	t.part:SetAttribute("GridY", gy)
	t.part:SetAttribute("AreaUID", folder.Name)
	if gx > maxX then maxX = gx end
	if gy > maxY then maxY = gy end
end

print(("[GridIndexer] Folder='%s' Cells=%d  du=%.3f dv=%.3f  Cols=%d Rows=%d  Origin=%s")
	:format(folder.Name, #cells, du, dv, maxX+1, maxY+1, useOrigin and "Yes" or "Auto"))