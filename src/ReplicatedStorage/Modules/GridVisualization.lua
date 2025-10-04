--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local PlacementSnap = require(Modules:WaitForChild("PlacementSnap"))

local VISUAL_UPDATE_FREQUENCY = 0.1
local GRID_SEARCH_RADIUS = 50
local STATION_SEARCH_FREQUENCY = 0.5
local SURFACE_INSET = 0.1

local COLOR_AVAILABLE = Color3.fromRGB(100, 255, 100)
local COLOR_OCCUPIED = Color3.fromRGB(255, 100, 100)
local COLOR_VALID_PLACEMENT = Color3.fromRGB(100, 200, 255)
local GUI_TRANSPARENCY = 0.5

local ActiveVisualization = false
local VisualizationCache: {[BasePart]: SurfaceGui} = {}
local LastVisualizationUpdate = 0
local LastStationSearch = 0
local CurrentStation: Model? = nil
local VisualizationConnection: RBXScriptConnection? = nil
local GridHidden: boolean = false

local function CreateCellIndicator(Cell: BasePart): SurfaceGui
	local SurfaceGui = Instance.new("SurfaceGui")
	SurfaceGui.Name = "GridIndicator"
	SurfaceGui.Face = Enum.NormalId.Top
	SurfaceGui.AlwaysOnTop = true
	SurfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	SurfaceGui.PixelsPerStud = 50

	local Frame = Instance.new("Frame")
	Frame.Name = "IndicatorFrame"
	Frame.BackgroundColor3 = COLOR_AVAILABLE
	Frame.BackgroundTransparency = GUI_TRANSPARENCY
	Frame.BorderSizePixel = 0

	local InsetScale = SURFACE_INSET
	Frame.AnchorPoint = Vector2.new(0.5, 0.5)
	Frame.Position = UDim2.fromScale(0.5, 0.5)
	Frame.Size = UDim2.fromScale(1 - InsetScale, 1 - InsetScale)

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0.1, 0)
	Corner.Parent = Frame

	Frame.Parent = SurfaceGui
	SurfaceGui.Parent = Cell

	return SurfaceGui
end

local function UpdateCellColor(SurfaceGui: SurfaceGui, Color: Color3)
	local Frame = SurfaceGui:FindFirstChild("IndicatorFrame")
	if Frame and Frame:IsA("Frame") then
		Frame.BackgroundColor3 = Color
	end
end

local function IsPlacementCell(Instance: Instance): boolean
	return Instance:IsA("BasePart") and Instance.Name == "PlacementCell"
end

local function FindNearestStation(Position: Vector3, PlayerUserId: number?): Model?
	if not PlayerUserId then
		return nil
	end

	local PlayerStation: Model? = nil
	local ClosestDistance = math.huge

	for _, Descendant in ipairs(workspace.Interactables:GetDescendants()) do
		if Descendant:IsA("Folder") and Descendant.Name == "PlacementGrid" then
			local Station = Descendant.Parent.Parent
			if Station and Station:IsA("Model") then
				local Owner = Station:GetAttribute("Owner")
				if Owner ~= PlayerUserId then
					continue
				end

				local StationPrimary = Station.PrimaryPart or Station:FindFirstChildWhichIsA("BasePart")
				if StationPrimary then
					local Distance = (StationPrimary.Position - Position).Magnitude

					if Distance < GRID_SEARCH_RADIUS and Distance < ClosestDistance then
						ClosestDistance = Distance
						PlayerStation = Station
					end
				end
			end
		end
	end

	return PlayerStation
end

local function GetGridCells(Station: Model): {BasePart}
	local Cells: {BasePart} = {}
	local GridFolder = Station:FindFirstChild("PlacementGrid", true)

	if GridFolder and GridFolder:IsA("Folder") then
		for _, Descendant in ipairs(GridFolder:GetDescendants()) do
			if Descendant:IsA("BasePart") and IsPlacementCell(Descendant) then
				table.insert(Cells, Descendant)
			end
		end
	end

	return Cells
end

local function IsCellOccupied(Cell: BasePart): boolean
	local OccCount = Cell:GetAttribute("OccCount")
	return (typeof(OccCount) == "number") and OccCount > 0
end

local function UpdateVisualization(DraggedObject: Instance?, PlayerUserId: number?, PlayerCharacter: Model?)
	local CurrentTime = tick()
	if CurrentTime - LastVisualizationUpdate < VISUAL_UPDATE_FREQUENCY then
		return
	end
	LastVisualizationUpdate = CurrentTime

	if not DraggedObject then
		return
	end

	local ObjectPosition: Vector3
	if DraggedObject:IsA("Model") then
		local Primary = DraggedObject.PrimaryPart or DraggedObject:FindFirstChildWhichIsA("BasePart")
		if not Primary then
			return
		end
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
			local BestDistance = math.huge

			for _, Cell in ipairs(Cells) do
				if IsPlacementCell(Cell) then
					local Distance = (Cell.Position - ObjectPosition).Magnitude
					if Distance < BestDistance then
						BestDistance = Distance
						NearestCell = Cell
					end
				end
			end

			if NearestCell then
				RotationToUse = PlacementSnap.CalculatePlayerRotationRelativeToCell(HRP.CFrame, NearestCell)
			end
		end
	end

	local ValidCellsSet: {[BasePart]: boolean} = {}

	local FootprintCells = PlacementSnap.FindNearestFreeFootprintOnSameStation(
		DraggedObject,
		PlacementSnap.SNAP_RADIUS,
		RotationToUse
	)

	if FootprintCells then
		for _, Cell in ipairs(FootprintCells) do
			ValidCellsSet[Cell] = true
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

local function CleanupVisualization()
	for _, Indicator in pairs(VisualizationCache) do
		if Indicator then
			Indicator:Destroy()
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

local function StartVisualization(DraggedObject: Instance, PlayerUserId: number?, PlayerCharacter: Model?)
	if ActiveVisualization then
		CleanupVisualization()
	end

	ActiveVisualization = true
	LastStationSearch = 0

	VisualizationConnection = RunService.Heartbeat:Connect(function()
		if DraggedObject and DraggedObject.Parent then
			UpdateVisualization(DraggedObject, PlayerUserId, PlayerCharacter)
		else
			CleanupVisualization()
		end
	end)
end

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