--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlacementSnap = require(Modules:WaitForChild("PlacementSnap"))

-- Constants
local VISUAL_UPDATE_FREQUENCY = 0.1
local GRID_SEARCH_RADIUS = 50
local STATION_SEARCH_FREQUENCY = 0.5
local SURFACE_INSET = 0.1

-- Colors
local COLOR_AVAILABLE = Color3.fromRGB(100, 255, 100)
local COLOR_OCCUPIED = Color3.fromRGB(255, 100, 100)
local COLOR_VALID_PLACEMENT = Color3.fromRGB(100, 200, 255)
local GUI_TRANSPARENCY = 0.5

-- State
local ActiveVisualization = false
local VisualizationCache: {[BasePart]: SurfaceGui} = {}
local LastVisualizationUpdate = 0
local LastStationSearch = 0
local CurrentStation: Model? = nil
local VisualizationConnection: RBXScriptConnection? = nil
local GridHidden: boolean = false

-- Create a SurfaceGui indicator on a cell
local function CreateCellIndicator(cell: BasePart): SurfaceGui
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "GridIndicator"
	surfaceGui.Face = Enum.NormalId.Top
	surfaceGui.AlwaysOnTop = true
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 50

	local frame = Instance.new("Frame")
	frame.Name = "IndicatorFrame"
	frame.BackgroundColor3 = COLOR_AVAILABLE
	frame.BackgroundTransparency = GUI_TRANSPARENCY
	frame.BorderSizePixel = 0

	local insetScale = SURFACE_INSET
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(1 - insetScale, 1 - insetScale)

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.1, 0)
	corner.Parent = frame

	frame.Parent = surfaceGui
	surfaceGui.Parent = cell

	return surfaceGui
end

-- Update the color of a cell indicator
local function UpdateCellColor(surfaceGui: SurfaceGui, color: Color3)
	local frame = surfaceGui:FindFirstChild("IndicatorFrame")
	if frame and frame:IsA("Frame") then
		frame.BackgroundColor3 = color
	end
end

-- Check if an instance is a placement cell
local function IsPlacementCell(instance: Instance): boolean
	return instance:IsA("BasePart") and instance.Name == "PlacementCell"
end

-- Find the nearest station/cart with a grid, ONLY if owned by player
local function FindNearestStation(position: Vector3, playerUserId: number?): Model?
    if not playerUserId then return nil end

	local playerStation: Model? = nil
	local closestDistance = math.huge

	for _, descendant in ipairs(workspace.Interactables:GetDescendants()) do
		if descendant:IsA("Folder") and descendant.Name == "PlacementGrid" then
			local station = descendant.Parent.Parent
			if station and station:IsA("Model") then
				local owner = station:GetAttribute("Owner")
				if owner ~= playerUserId then
					continue -- Skip non-owned stations
				end
				
				local stationPrimary = station.PrimaryPart or station:FindFirstChildWhichIsA("BasePart")
				if stationPrimary then
					local distance = (stationPrimary.Position - position).Magnitude

					if distance < GRID_SEARCH_RADIUS and distance < closestDistance then
						closestDistance = distance
						playerStation = station
					end
				end
			end
		end
	end

	return playerStation
end

-- Get all grid cells from a station
local function GetGridCells(station: Model): {BasePart}
	local cells: {BasePart} = {}
	local gridFolder = station:FindFirstChild("PlacementGrid", true)

	if gridFolder and gridFolder:IsA("Folder") then
		for _, descendant in ipairs(gridFolder:GetDescendants()) do
			if descendant:IsA("BasePart") and IsPlacementCell(descendant) then
				table.insert(cells, descendant)
			end
		end
	end

	return cells
end

-- Check if a cell is occupied
local function IsCellOccupied(cell: BasePart): boolean
	local occCount = cell:GetAttribute("OccCount")
	return (typeof(occCount) == "number") and occCount > 0
end

-- Update visualization for all cells
local function UpdateVisualization(DraggedObject: Instance?, PlayerUserId: number?, PlayerCharacter: Model?)
	local CurrentTime = tick()
	if CurrentTime - LastVisualizationUpdate < VISUAL_UPDATE_FREQUENCY then
		return
	end
	LastVisualizationUpdate = CurrentTime

	if not DraggedObject then return end

	local ObjectPosition: Vector3
	if DraggedObject:IsA("Model") then
		local Primary = DraggedObject.PrimaryPart or DraggedObject:FindFirstChildWhichIsA("BasePart")
		if not Primary then return end
		ObjectPosition = Primary.Position
	elseif DraggedObject:IsA("BasePart") then
		ObjectPosition = DraggedObject.Position
	else
		return
	end

	if CurrentTime - LastStationSearch > STATION_SEARCH_FREQUENCY then
		LastStationSearch = CurrentTime
		CurrentStation = FindNearestStation(ObjectPosition, PlayerUserId)
	end

	if not CurrentStation or not CurrentStation.Parent then
		for _, Indicator in pairs(VisualizationCache) do
			if Indicator then
				Indicator.Enabled = false
			end
		end
		return
	end

	local Cells = GetGridCells(CurrentStation)
	local RotationToUse: number? = nil
	
	if PlayerCharacter then
		local HRP = PlayerCharacter:FindFirstChild("HumanoidRootPart")
		if HRP and HRP:IsA("BasePart") then
			local NearestCell: BasePart? = nil
			local BestDist = math.huge
			for _, Cell in ipairs(Cells) do
				if IsPlacementCell(Cell) then
					local Distance = (Cell.Position - ObjectPosition).Magnitude
					if Distance < BestDist then
						BestDist = Distance
						NearestCell = Cell
					end
				end
			end

			if NearestCell then
				RotationToUse = PlacementSnap.CalculatePlayerRotationRelativeToCell(HRP.CFrame, NearestCell)
			end
		end
	end

	local ValidPlacementCells: {BasePart} = {}
	local ValidCellsSet: {[BasePart]: boolean} = {}

	local FootprintCells = PlacementSnap.FindNearestFreeFootprintOnSameStation(
		DraggedObject, 
		PlacementSnap.SNAP_RADIUS,
		RotationToUse
	)

	if FootprintCells then
		for _, Cell in ipairs(FootprintCells) do
			ValidCellsSet[Cell] = true
			table.insert(ValidPlacementCells, Cell)
		end
	end

	local UpdatedCells: {[BasePart]: boolean} = {}

	for _, Cell in ipairs(Cells) do
		if IsPlacementCell(Cell) then
			UpdatedCells[Cell] = true

			local Distance = (Cell.Position - ObjectPosition).Magnitude
			if Distance <= GRID_SEARCH_RADIUS then
				local Indicator = VisualizationCache[Cell]
				if not Indicator or not Indicator.Parent then
					Indicator = CreateCellIndicator(Cell)
					VisualizationCache[Cell] = Indicator
				end

				local Color: Color3
				if ValidCellsSet[Cell] then
					Color = COLOR_VALID_PLACEMENT
				elseif IsCellOccupied(Cell) then
					Color = COLOR_OCCUPIED
				else
					Color = COLOR_AVAILABLE
				end

				UpdateCellColor(Indicator, Color)
				Indicator.Enabled = not GridHidden
			else
				local Indicator = VisualizationCache[Cell]
				if Indicator then
					Indicator.Enabled = false
				end
			end
		end
	end

	for Cell, Indicator in pairs(VisualizationCache) do
		if not UpdatedCells[Cell] or not IsPlacementCell(Cell) then
			if Indicator then
				Indicator:Destroy()
			end
			VisualizationCache[Cell] = nil
		end
	end
end

-- Clean up all visualization
local function CleanupVisualization()
	for cell, indicator in pairs(VisualizationCache) do
		if indicator then
			indicator:Destroy()
		end
	end
	VisualizationCache = {}
	CurrentStation = nil
	LastStationSearch = 0

	if VisualizationConnection then
		VisualizationConnection:Disconnect()
		VisualizationConnection = nil
	end

	ActiveVisualization = false
end

-- Start showing grid visualization
local function StartVisualization(draggedObject: Instance, playerUserId: number?, playerCharacter: Model?)
	if ActiveVisualization then
		CleanupVisualization()
	end

	-- Don't show grid for wheels
	-- if draggedObject:IsA("Model") and draggedObject:GetAttribute("PartType") == "Wheel" then
	-- 	return
	-- end

	ActiveVisualization = true
	LastStationSearch = 0

	VisualizationConnection = RunService.Heartbeat:Connect(function()
		if draggedObject and draggedObject.Parent then
			UpdateVisualization(draggedObject, playerUserId, playerCharacter)
		else
			CleanupVisualization()
		end
	end)
end

-- Stop showing grid visualization
local function StopVisualization()
	CleanupVisualization()
end

local function HideGrid()
	GridHidden = true
	for _, Indicator in pairs(VisualizationCache) do
		if Indicator then
			Indicator.Enabled = false
		end
	end
end

local function ShowGrid()
	GridHidden = false
	for _, Indicator in pairs(VisualizationCache) do
		if Indicator then
			Indicator.Enabled = true
		end
	end
end

return {
	StartVisualization = StartVisualization,
	StopVisualization = StopVisualization,
	CleanupVisualization = CleanupVisualization,
	HideGrid = HideGrid,
	ShowGrid = ShowGrid,
	RemoveAllHighlights = function()
		for _, Descendant in ipairs(workspace:GetDescendants()) do
			if Descendant:IsA("Highlight") and Descendant.Name == "DragHighlight" then
				Descendant:Destroy()
			end
		end
	end
}