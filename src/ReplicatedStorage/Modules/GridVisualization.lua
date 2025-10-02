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
				-- CRITICAL: Only consider stations owned by this player
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
local function UpdateVisualization(draggedObject: Instance?, playerUserId: number?, playerCharacter: Model?)
	local currentTime = tick()
	if currentTime - LastVisualizationUpdate < VISUAL_UPDATE_FREQUENCY then
		return
	end
	LastVisualizationUpdate = currentTime

	if not draggedObject then return end

	local objectPosition: Vector3
	if draggedObject:IsA("Model") then
		local primary = draggedObject.PrimaryPart or draggedObject:FindFirstChildWhichIsA("BasePart")
		if not primary then return end
		objectPosition = primary.Position
	elseif draggedObject:IsA("BasePart") then
		objectPosition = draggedObject.Position
	else
		return
	end

	-- Periodically re-search for nearest station
	if currentTime - LastStationSearch > STATION_SEARCH_FREQUENCY then
		LastStationSearch = currentTime
		CurrentStation = FindNearestStation(objectPosition, playerUserId)
	end

	if not CurrentStation or not CurrentStation.Parent then
		-- Clear all indicators if no station found
		for _, indicator in pairs(VisualizationCache) do
			if indicator then
				indicator.Enabled = false
			end
		end
		return
	end

	local cells = GetGridCells(CurrentStation)

	-- Calculate player rotation for footprint search
	local rotationToUse: number? = nil
	if playerCharacter then
		local hrp = playerCharacter:FindFirstChild("HumanoidRootPart")
		if hrp and hrp:IsA("BasePart") then
			local nearestCell: BasePart? = nil
			local bestDist = math.huge
			for _, cell in ipairs(cells) do
				if IsPlacementCell(cell) then
					local d = (cell.Position - objectPosition).Magnitude
					if d < bestDist then
						bestDist = d
						nearestCell = cell
					end
				end
			end

			if nearestCell then
				-- Use shared function from PlacementSnap
				rotationToUse = PlacementSnap.CalculatePlayerRotationRelativeToCell(hrp.CFrame, nearestCell)
			end
		end
	end

	-- Find valid placement cells for current object WITH rotation
	local validPlacementCells: {BasePart} = {}
	local validCellsSet: {[BasePart]: boolean} = {}

	local footprintCells = PlacementSnap.FindNearestFreeFootprintOnSameStation(
		draggedObject, 
		PlacementSnap.SNAP_RADIUS,
		rotationToUse
	)

	if footprintCells then
		for _, cell in ipairs(footprintCells) do
			validCellsSet[cell] = true
			table.insert(validPlacementCells, cell)
		end
	end

	local updatedCells: {[BasePart]: boolean} = {}

	-- Update or create indicators for each cell
	for _, cell in ipairs(cells) do
		if IsPlacementCell(cell) then
			updatedCells[cell] = true

			local distance = (cell.Position - objectPosition).Magnitude
			if distance <= GRID_SEARCH_RADIUS then
				local indicator = VisualizationCache[cell]
				if not indicator or not indicator.Parent then
					indicator = CreateCellIndicator(cell)
					VisualizationCache[cell] = indicator
				end

				local color: Color3
				if validCellsSet[cell] then
					color = COLOR_VALID_PLACEMENT
				elseif IsCellOccupied(cell) then
					color = COLOR_OCCUPIED
				else
					color = COLOR_AVAILABLE
				end

				UpdateCellColor(indicator, color)
				indicator.Enabled = true
			else
				local indicator = VisualizationCache[cell]
				if indicator then
					indicator.Enabled = false
				end
			end
		end
	end

	-- Clean up indicators for cells that are no longer valid
	for cell, indicator in pairs(VisualizationCache) do
		if not updatedCells[cell] or not IsPlacementCell(cell) then
			if indicator then
				indicator:Destroy()
			end
			VisualizationCache[cell] = nil
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
	if draggedObject:IsA("Model") and draggedObject:GetAttribute("PartType") == "Wheel" then
		return
	end

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

return {
	StartVisualization = StartVisualization,
	StopVisualization = StopVisualization,
	CleanupVisualization = CleanupVisualization,
	RemoveAllHighlights = function()
		for _, descendant in ipairs(workspace:GetDescendants()) do
			if descendant:IsA("Highlight") and descendant.Name == "DragHighlight" then
				descendant:Destroy()
			end
		end
	end
}