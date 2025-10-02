--!strict
local PlacementGrid = {}

local Workspace = game:GetService("Workspace")
local PlacementFootprint = require(script.Parent:WaitForChild("PlacementFootprint"))

export type CellMeta = {
	cell: BasePart,
	x: number,
	y: number,
	area: string,
}

export type GridIndex = {
	all: {CellMeta},
	byArea: {[string]: {[string]: BasePart}}
}

local CFG = {
	PLACEMENT_GRID_NAME = "PlacementGrid",
}

-- Read cell metadata from attributes
local function ReadCellMeta(cell: BasePart): CellMeta?
	local x = cell:GetAttribute("GridX")
	local y = cell:GetAttribute("GridY")
	local a = cell:GetAttribute("AreaUID")
	if typeof(x) ~= "number" or typeof(y) ~= "number" or typeof(a) ~= "string" then
		return nil
	end
	return { cell = cell, x = x, y = y, area = a }
end

-- Build searchable index of all grid cells in a station
function PlacementGrid.BuildIndex(station: Model): GridIndex?
	local gridFolder = station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
	if not gridFolder then return nil end

	local byArea: {[string]: {[string]: BasePart}} = {}
	local list: {CellMeta} = {}

	for _, c in ipairs(gridFolder:GetDescendants()) do
		if c:IsA("BasePart") then
			local meta = ReadCellMeta(c)
			if meta then
				table.insert(list, meta)
				local areaTable = byArea[meta.area]
				if not areaTable then
					areaTable = {}
					byArea[meta.area] = areaTable
				end
				areaTable[("%d,%d"):format(meta.x, meta.y)] = c
			end
		end
	end

	return { all = list, byArea = byArea }
end

-- Get cell occupancy count
function PlacementGrid.GetOccupancyCount(cell: BasePart): number
	local n = cell:GetAttribute("OccCount")
	return (typeof(n) == "number") and n or 0
end

-- Set cell occupancy count
function PlacementGrid.SetOccupancyCount(cell: BasePart, count: number): ()
	count = math.max(0, count)
	cell:SetAttribute("OccCount", count)
	-- Keep legacy boolean in sync
	if count > 0 then 
		cell:SetAttribute("Occupied", true) 
	else 
		cell:SetAttribute("Occupied", nil) 
	end
end

-- Check if cell is available (not occupied)
function PlacementGrid.IsCellAvailable(cell: BasePart): boolean
	return PlacementGrid.GetOccupancyCount(cell) == 0
end

-- Mark cell as occupied or free
function PlacementGrid.MarkCell(cell: BasePart, occupied: boolean): ()
	if occupied then
		PlacementGrid.SetOccupancyCount(cell, PlacementGrid.GetOccupancyCount(cell) + 1)
	else
		PlacementGrid.SetOccupancyCount(cell, PlacementGrid.GetOccupancyCount(cell) - 1)
	end
end

-- Mark multiple cells
function PlacementGrid.MarkCells(cells: {BasePart}, occupied: boolean): ()
	for _, c in ipairs(cells) do
		PlacementGrid.MarkCell(c, occupied)
	end
end

-- Find rectangular footprint of cells starting from origin
function PlacementGrid.FindFootprintCells(
	index: GridIndex, 
	area: string, 
	originX: number, 
	originY: number, 
	footprint: any
): {BasePart}?
	local cells: {BasePart} = {}
	local seen: {[BasePart]: boolean} = {}
	local need = footprint.X * footprint.Y

	for dy = 0, footprint.Y - 1 do
		for dx = 0, footprint.X - 1 do
			local key = ("%d,%d"):format(originX + dx, originY + dy)
			local c = (index.byArea[area] and index.byArea[area][key]) or nil

			-- Check if cell exists, not duplicate, AND is available
			if not c or seen[c] or not PlacementGrid.IsCellAvailable(c) then
				return nil
			end

			seen[c] = true
			table.insert(cells, c)
		end
	end

	-- Must be exact size
	if #cells ~= need then return nil end
	return cells
end

-- Get station model from a cell
function PlacementGrid.GetStationFromCell(cell: BasePart): Model?
	local grid = cell.Parent
	local station = grid and grid.Parent and grid.Parent.Parent and grid.Parent.Parent.Parent
	return (station and station:IsA("Model")) and station or nil
end

-- Find nearest available cell within radius
function PlacementGrid.FindNearestAvailableCell(station: Model, position: Vector3, radius: number): BasePart?
	local grid = station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
	if not grid or not grid:IsA("Folder") then return nil end

	local nearest: BasePart? = nil
	local best = math.huge

	for _, cell in ipairs(grid:GetDescendants()) do
		if cell:IsA("BasePart") and PlacementGrid.IsCellAvailable(cell) then
			local d = (cell.Position - position).Magnitude
			if d <= radius and d < best then
				best = d
				nearest = cell
			end
		end
	end

	return nearest
end

-- Check if a station has enough free space for a footprint
function PlacementGrid.HasAvailableSpace(station: Model, requiredFootprint: any): boolean
	if not station then return false end

	local index = PlacementGrid.BuildIndex(station)
	if not index then return false end

	local need = requiredFootprint.X * requiredFootprint.Y

	for _, meta in ipairs(index.all) do
		local patch = PlacementGrid.FindFootprintCells(index, meta.area, meta.x, meta.y, requiredFootprint)
		if patch and #patch == need then
			return true
		end
	end

	return false
end

-- Get total free cell count
function PlacementGrid.GetFreeCellCount(station: Model): number
	if not station then return 0 end

	local gridFolder = station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
	if not gridFolder or not gridFolder:IsA("Folder") then return 0 end

	local freeCount = 0
	for _, cell in ipairs(gridFolder:GetDescendants()) do
		if cell:IsA("BasePart") and PlacementGrid.IsCellAvailable(cell) then
			freeCount += 1
		end
	end

	return freeCount
end

-- Get total cell count
function PlacementGrid.GetTotalCellCount(station: Model): number
	if not station then return 0 end

	local gridFolder = station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
	if not gridFolder or not gridFolder:IsA("Folder") then return 0 end

	local totalCount = 0
	for _, cell in ipairs(gridFolder:GetDescendants()) do
		if cell:IsA("BasePart") then
			totalCount += 1
		end
	end

	return totalCount
end

return PlacementGrid