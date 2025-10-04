--!strict
local PlacementGrid = {}

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

local function ReadCellMeta(Cell: BasePart): CellMeta?
	local GridX = Cell:GetAttribute("GridX")
	local GridY = Cell:GetAttribute("GridY")
	local AreaUID = Cell:GetAttribute("AreaUID")

	if typeof(GridX) ~= "number" or typeof(GridY) ~= "number" or typeof(AreaUID) ~= "string" then
		return nil
	end

	return { cell = Cell, x = GridX, y = GridY, area = AreaUID }
end

function PlacementGrid.BuildIndex(Station: Model): GridIndex?
	local GridFolder = Station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
	if not GridFolder then
		return nil
	end

	local ByArea: {[string]: {[string]: BasePart}} = {}
	local CellList: {CellMeta} = {}

	for _, Child in ipairs(GridFolder:GetDescendants()) do
		if Child:IsA("BasePart") then
			local Meta = ReadCellMeta(Child)
			if Meta then
				table.insert(CellList, Meta)

				local AreaTable = ByArea[Meta.area]
				if not AreaTable then
					AreaTable = {}
					ByArea[Meta.area] = AreaTable
				end
				AreaTable[("%d,%d"):format(Meta.x, Meta.y)] = Child
			end
		end
	end

	return { all = CellList, byArea = ByArea }
end

function PlacementGrid.GetOccupancyCount(Cell: BasePart): number
	local Count = Cell:GetAttribute("OccCount")
	return (typeof(Count) == "number") and Count or 0
end

function PlacementGrid.SetOccupancyCount(Cell: BasePart, Count: number): ()
	Count = math.max(0, Count)
	Cell:SetAttribute("OccCount", Count)

	if Count > 0 then
		Cell:SetAttribute("Occupied", true)
	else
		Cell:SetAttribute("Occupied", nil)
	end
end

function PlacementGrid.IsCellAvailable(Cell: BasePart): boolean
	return PlacementGrid.GetOccupancyCount(Cell) == 0
end

function PlacementGrid.MarkCell(Cell: BasePart, Occupied: boolean): ()
	if Occupied then
		PlacementGrid.SetOccupancyCount(Cell, PlacementGrid.GetOccupancyCount(Cell) + 1)
	else
		PlacementGrid.SetOccupancyCount(Cell, PlacementGrid.GetOccupancyCount(Cell) - 1)
	end
end

function PlacementGrid.MarkCells(Cells: {BasePart}, Occupied: boolean): ()
	for _, Cell in ipairs(Cells) do
		PlacementGrid.MarkCell(Cell, Occupied)
	end
end

function PlacementGrid.FindFootprintCells(
	Index: GridIndex,
	Area: string,
	OriginX: number,
	OriginY: number,
	Footprint: any
): {BasePart}?
	local ResultCells: {BasePart} = {}
	local SeenCells: {[BasePart]: boolean} = {}
	local NeededCount = Footprint.X * Footprint.Y

	for DeltaY = 0, Footprint.Y - 1 do
		for DeltaX = 0, Footprint.X - 1 do
			local Key = ("%d,%d"):format(OriginX + DeltaX, OriginY + DeltaY)
			local Cell = (Index.byArea[Area] and Index.byArea[Area][Key]) or nil

			if not Cell or SeenCells[Cell] or not PlacementGrid.IsCellAvailable(Cell) then
				return nil
			end

			SeenCells[Cell] = true
			table.insert(ResultCells, Cell)
		end
	end

	if #ResultCells ~= NeededCount then
		return nil
	end

	return ResultCells
end

function PlacementGrid.GetStationFromCell(Cell: BasePart): Model?
	local Grid = Cell.Parent
	local Station = Grid and Grid.Parent and Grid.Parent.Parent and Grid.Parent.Parent.Parent
	return (Station and Station:IsA("Model")) and Station or nil
end

function PlacementGrid.FindNearestAvailableCell(Station: Model, Position: Vector3, Radius: number): BasePart?
	local Grid = Station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
	if not Grid or not Grid:IsA("Folder") then
		return nil
	end

	local NearestCell: BasePart? = nil
	local BestDistance = math.huge

	for _, Cell in ipairs(Grid:GetDescendants()) do
		if Cell:IsA("BasePart") and PlacementGrid.IsCellAvailable(Cell) then
			local Distance = (Cell.Position - Position).Magnitude
			if Distance <= Radius and Distance < BestDistance then
				BestDistance = Distance
				NearestCell = Cell
			end
		end
	end

	return NearestCell
end

function PlacementGrid.HasAvailableSpace(Station: Model, RequiredFootprint: any): boolean
	if not Station then
		return false
	end

	local Index = PlacementGrid.BuildIndex(Station)
	if not Index then
		return false
	end

	local NeededCount = RequiredFootprint.X * RequiredFootprint.Y

	for _, Meta in ipairs(Index.all) do
		local Patch = PlacementGrid.FindFootprintCells(Index, Meta.area, Meta.x, Meta.y, RequiredFootprint)
		if Patch and #Patch == NeededCount then
			return true
		end
	end

	return false
end

function PlacementGrid.GetFreeCellCount(Station: Model): number
	if not Station then
		return 0
	end

	local GridFolder = Station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
	if not GridFolder or not GridFolder:IsA("Folder") then
		return 0
	end

	local FreeCount = 0
	for _, Cell in ipairs(GridFolder:GetDescendants()) do
		if Cell:IsA("BasePart") and PlacementGrid.IsCellAvailable(Cell) then
			FreeCount += 1
		end
	end

	return FreeCount
end

function PlacementGrid.GetTotalCellCount(Station: Model): number
	if not Station then
		return 0
	end

	local GridFolder = Station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
	if not GridFolder or not GridFolder:IsA("Folder") then
		return 0
	end

	local TotalCount = 0
	for _, Cell in ipairs(GridFolder:GetDescendants()) do
		if Cell:IsA("BasePart") then
			TotalCount += 1
		end
	end

	return TotalCount
end

return PlacementGrid