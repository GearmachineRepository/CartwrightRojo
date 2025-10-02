--!strict
local PlacementSnap = {
	SNAP_RADIUS = 5,
}

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Modules = script.Parent
local PlacementFootprint = require(Modules:WaitForChild("PlacementFootprint"))
local PlacementGrid = require(Modules:WaitForChild("PlacementGrid"))
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))

local CFG = {
	PLACEMENT_GRID_NAME = "PlacementGrid",
	PLACEMENT_WELD_NAME = "PlacementWeld",
	PLACEMENT_CELL_REF_NAME = "PlacementCell",
	ORIGINAL_PARENT_REF_NAME = "OriginalParent",
	DRAG_TAG = "Drag",
	ALIGN_ORIENTATION = true,
}

local CELL_REFS_FOLDER_NAME = "PlacementCells"

-- Utils
local function IsAncestorOf(a: Instance, b: Instance): boolean
	return b:IsDescendantOf(a)
end

function PlacementSnap.GetRootPart(inst: Instance): BasePart?
	if inst:IsA("BasePart") then return inst end
	if inst:IsA("Model") then
		local m = inst :: Model
		return m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function EnsurePrimary(model: Model): BasePart?
	if model.PrimaryPart and model.PrimaryPart:IsDescendantOf(model) then
		return model.PrimaryPart
	end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			model.PrimaryPart = d
			return d
		end
	end
	return nil
end

-- Cell reference management
local function GetCellRef(target: Instance): ObjectValue?
	return target:FindFirstChild(CFG.PLACEMENT_CELL_REF_NAME) :: ObjectValue
end

local function SetCellRef(target: Instance, cell: BasePart?)
	local ref: any = GetCellRef(target)
	if cell then
		if not ref then
			local NewRef = Instance.new("ObjectValue")
			NewRef.Name = CFG.PLACEMENT_CELL_REF_NAME
			NewRef.Parent = target
			ref = NewRef
		end
		ref.Value = cell
	else
		if ref then ref:Destroy() end
	end
end

local function GetOriginalParentRef(target: Instance): ObjectValue?
	return target:FindFirstChild(CFG.ORIGINAL_PARENT_REF_NAME) :: ObjectValue
end

local function SetOriginalParentRef(target: Instance, parentInst: Instance?)
	local ref = GetOriginalParentRef(target)
	if parentInst then
		if not ref then
			ref = Instance.new("ObjectValue")
			ref.Name = CFG.ORIGINAL_PARENT_REF_NAME
			ref.Parent = target
		end
		ref.Value = parentInst
	else
		if ref then ref:Destroy() end
	end
end

local function GetOrCreateCellsFolder(target: Instance): Folder
	local f = target:FindFirstChild(CELL_REFS_FOLDER_NAME)
	if not f then
		f = Instance.new("Folder")
		f.Name = CELL_REFS_FOLDER_NAME
		f.Parent = target
	end
	return f :: Folder
end

local function ClearCellsFolder(target: Instance)
	local f = target:FindFirstChild(CELL_REFS_FOLDER_NAME)
	if f then
		for _, ch in ipairs(f:GetChildren()) do ch:Destroy() end
	end
end

-- Find station for target
local function FindNearestStation(target: Instance, radius: number): Model?
	local root = PlacementSnap.GetRootPart(target)
	if not root then return nil end

	local ref = GetCellRef(target)
	if ref and ref.Value and ref.Value:IsA("BasePart") then
		return PlacementGrid.GetStationFromCell(ref.Value)
	end

	local bestDist = math.huge
	local station: Model? = nil

	for _, folder in ipairs(Workspace:GetDescendants()) do
		if folder:IsA("Folder") and folder.Name == CFG.PLACEMENT_GRID_NAME then
			local par = folder.Parent
			if par and par:IsA("Model") then
				local pp = EnsurePrimary(par)
				if pp then
					local d = (pp.Position - root.Position).Magnitude
					if d < bestDist then
						bestDist = d
						station = par
					end
				end
			end
		end
	end

	return station
end

-- Public: Find nearest free footprint on same station
function PlacementSnap.FindNearestFreeFootprintOnSameStation(
	target: Instance, 
	radius: number?, 
	rotationDegrees: number?
): {BasePart}?
	local root = PlacementSnap.GetRootPart(target)
	if not root then return nil end

	local baseFp = PlacementFootprint.GetFootprint(target)
	local fp = PlacementFootprint.ApplyRotation(baseFp, rotationDegrees)
	local need = PlacementFootprint.GetCellCount(fp)
	local R = radius or PlacementSnap.SNAP_RADIUS

	local station = FindNearestStation(target, R)
	if not station then return nil end

	local index = PlacementGrid.BuildIndex(station)
	if not index then return nil end

	-- Sort cells by distance
	table.sort(index.all, function(a, b)
		local da = (a.cell.Position - root.Position).Magnitude
		local db = (b.cell.Position - root.Position).Magnitude
		return da < db
	end)

	for _, meta in ipairs(index.all) do
		local dist = (meta.cell.Position - root.Position).Magnitude
		if dist <= R then
			local patch = PlacementGrid.FindFootprintCells(index, meta.area, meta.x, meta.y, fp)
			if patch and #patch == need then
				return patch
			end
		end
	end

	return nil
end

-- Weld management
function PlacementSnap.DestroyPlacementWeldsFor(root: BasePart)
	for _, ch in ipairs(root:GetChildren()) do
		if ch:IsA("WeldConstraint") and ch.Name == CFG.PLACEMENT_WELD_NAME then
			ch:Destroy()
		end
	end
end

-- Public: Unsnap
function PlacementSnap.UnsnapFromPlacementCell(target: Instance, _Player: Player?)
	local root = PlacementSnap.GetRootPart(target)
	if not root then return end

	PlacementSnap.DestroyPlacementWeldsFor(root)

	-- Clear multi-cell reservations
	local cellsFolder = target:FindFirstChild(CELL_REFS_FOLDER_NAME)
	if cellsFolder then
		for _, ov in ipairs(cellsFolder:GetChildren()) do
			if ov:IsA("ObjectValue") and ov.Value and ov.Value:IsA("BasePart") then
				PlacementGrid.MarkCell(ov.Value, false)
			end
		end
		cellsFolder:ClearAllChildren()
	end

	-- Legacy single-cell ref
	local ref = GetCellRef(target)
	if ref and ref.Value and ref.Value:IsA("BasePart") then
		PlacementGrid.MarkCell(ref.Value, false)
	end

	local op = GetOriginalParentRef(target)
	if op and op.Value then
		target.Parent = op.Value
	end

	SetCellRef(target, nil)
	SetOriginalParentRef(target, nil)
	ObjectStateManager.ForceIdle(target)

	if not CollectionService:HasTag(target, CFG.DRAG_TAG) then
		CollectionService:AddTag(target, CFG.DRAG_TAG)
	end

	pcall(function()
		if root:IsDescendantOf(Workspace) and not root.Anchored then
			root:SetNetworkOwnershipAuto()
		end
	end)
end

-- Public: Snap to cells
function PlacementSnap.SnapToCells(
	target: Instance, 
	cells: any, 
	alignOrientation: boolean?, 
	Player: Player?, 
	manualRotationDegrees: number?
)
	-- Accept single cell or list
	if typeof(cells) == "Instance" and cells:IsA("BasePart") then
		cells = { cells }
	elseif typeof(cells) ~= "table" then
		warn("[PlacementSnap] SnapToCells expected BasePart or {BasePart}, got:", typeof(cells))
		return
	end
	if #cells == 0 then return end

	-- Verify all cells available
	for _, c in ipairs(cells) do
		if not PlacementGrid.IsCellAvailable(c) then
			warn("[PlacementSnap] Cannot snap - one or more cells already occupied")
			return
		end
	end

	-- Cart part guard
	if target:GetAttribute("PartType") then return end
	local root = PlacementSnap.GetRootPart(target)
	if not root then return end

	local firstCell: BasePart = cells[1]
	local station = PlacementGrid.GetStationFromCell(firstCell)
	if not (station and station:IsA("Model")) then return end
	EnsurePrimary(station)
	if target == station or IsAncestorOf(target, firstCell) then return end

	-- CRITICAL: Clear any existing drag state before snapping
	if target:GetAttribute("BeingDragged") then
		warn("[PlacementSnap] Object was still BeingDragged, clearing state before snap")
		ObjectStateManager.ForceIdle(target)
	end

	PlacementSnap.DestroyPlacementWeldsFor(root)

	-- Remember original parent
	if not GetOriginalParentRef(target) then
		SetOriginalParentRef(target, target.Parent)
	end

	-- Disable aligns
	local ap = root:FindFirstChildOfClass("AlignPosition")
	if ap then ap.Enabled = false ap.Attachment0 = nil end
	local ao = root:FindFirstChildOfClass("AlignOrientation")
	if ao then ao.Enabled = false ao.Attachment0 = nil end
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
	root.Anchored = false

	-- Compute center
	local sum = Vector3.zero
	for _, c in ipairs(cells) do sum += c.Position end
	local centerPos = sum / #cells

	-- Orientation
	local doOrient = (alignOrientation ~= nil) and alignOrientation or CFG.ALIGN_ORIENTATION
	local targetCF
	if doOrient then
		local baseCF = CFrame.new(centerPos) * (firstCell.CFrame - firstCell.Position)

		if Player and not manualRotationDegrees then
			local character = Player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp and hrp:IsA("BasePart") then
					local cellForward = firstCell.CFrame.LookVector
					local playerForward = hrp.CFrame.LookVector

					local playerForwardFlat = Vector3.new(playerForward.X, 0, playerForward.Z).Unit
					local cellForwardFlat = Vector3.new(cellForward.X, 0, cellForward.Z).Unit

					local dotProduct = cellForwardFlat:Dot(playerForwardFlat)
					local crossProduct = cellForwardFlat:Cross(playerForwardFlat).Y
					local relativeAngle = math.atan2(crossProduct, dotProduct)

					local snappedRelativeAngle = math.round(relativeAngle / (math.pi/2)) * (math.pi/2)

					targetCF = baseCF * CFrame.Angles(0, snappedRelativeAngle, 0)
				else
					targetCF = baseCF
				end
			else
				targetCF = baseCF
			end
		elseif manualRotationDegrees then
			local manualRotationRad = math.rad(manualRotationDegrees)
			targetCF = baseCF * CFrame.Angles(0, manualRotationRad, 0)
		else
			targetCF = baseCF
		end
	else
		targetCF = CFrame.new(centerPos)
	end

	-- Height offset
	local itemHeight = 0
	if target:IsA("Model") then
		local cf, size = target:GetBoundingBox()
		itemHeight = size.Y
	elseif target:IsA("BasePart") then
		itemHeight = target.Size.Y
	end

	local cellHeight = firstCell.Size.Y
	local heightOffset = ((cellHeight/2) + (itemHeight / 2)) - cellHeight

	-- Place
	if target:IsA("Model") then
		target:PivotTo(targetCF * CFrame.new(0, heightOffset, 0))
	else
		root.CFrame = targetCF * CFrame.new(0, cellHeight, 0)
	end

	-- Weld
	local weld = Instance.new("WeldConstraint")
	weld.Name = CFG.PLACEMENT_WELD_NAME
	weld.Part0 = firstCell
	weld.Part1 = root
	weld.Parent = root

	target.Parent = firstCell

	-- Mark occupied
	PlacementGrid.MarkCells(cells, true)
	SetCellRef(target, firstCell)

	ClearCellsFolder(target)
	local folder = GetOrCreateCellsFolder(target)
	for _, c in ipairs(cells) do
		local ov = Instance.new("ObjectValue")
		ov.Name = "Cell"
		ov.Value = c
		ov.Parent = folder
	end

	ObjectStateManager.SetState(target, "SnappedToGrid")
	if Player then target:SetAttribute("Owner", Player.UserId or Player:GetAttribute("Id")) end
	if not CollectionService:HasTag(target, CFG.DRAG_TAG) then
		CollectionService:AddTag(target, CFG.DRAG_TAG)
	end

	-- Settle
	task.defer(function()
		if root.Parent then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			pcall(function() root:SetNetworkOwnershipAuto() end)
		end
	end)
end

-- Back-compat wrapper
function PlacementSnap.SnapToPlacementCell(
	target: Instance, 
	cell: BasePart, 
	alignOrientation: boolean?, 
	Player: Player?, 
	manualRotationDegrees: number?
)
	if not cell or not cell:IsA("BasePart") then return end
	PlacementSnap.SnapToCells({cell}, alignOrientation, Player, manualRotationDegrees)
end

-- Public: Find nearest free cell
function PlacementSnap.FindNearestFreeCellOnSameStation(target: Instance, radius: number?): BasePart?
	local root = PlacementSnap.GetRootPart(target)
	if not root then return nil end

	local station = FindNearestStation(target, radius or PlacementSnap.SNAP_RADIUS)
	if not station then return nil end

	return PlacementGrid.FindNearestAvailableCell(station, root.Position, radius or PlacementSnap.SNAP_RADIUS)
end

-- Public: Auto-unsnap hooks
function PlacementSnap.BindAutoUnsnapHooks(target: Instance): (() -> ())
	local conns: {RBXScriptConnection} = {}

	local function ShouldUnsnap(): boolean
		if not target.Parent then return true end
		if target:IsDescendantOf(game:GetService("Players")) then return true end
		local p = target.Parent
		if p:IsA("Backpack") or p:IsA("Tool") or p:IsA("Accessory") then return true end

		local cellRef = GetCellRef(target)
		if cellRef and cellRef.Value then
			if not target:IsDescendantOf(cellRef.Value) then
				return true
			end
		end
		return false
	end

	table.insert(conns, target.AncestryChanged:Connect(function()
		if target:GetAttribute("SnappedToGrid") and ShouldUnsnap() then
			PlacementSnap.UnsnapFromPlacementCell(target)
		end
	end))
	table.insert(conns, target:GetPropertyChangedSignal("Parent"):Connect(function()
		if target:GetAttribute("SnappedToGrid") and ShouldUnsnap() then
			PlacementSnap.UnsnapFromPlacementCell(target)
		end
	end))

	return function()
		for _, c in ipairs(conns) do c:Disconnect() end
	end
end

-- Convenience: Try snap nearest footprint
function PlacementSnap.TrySnapNearestFootprint(
	target: Instance, 
	radius: number?, 
	Player: Player?, 
	manualRotationDegrees: number?
): boolean
	-- Skip wheels
	if target:IsA("Model") and target:GetAttribute("PartType") == "Wheel" then
		return false
	end

	local fp = PlacementFootprint.GetFootprint(target)

	-- Calculate rotation
	local rotationToUse = manualRotationDegrees
	if not rotationToUse and Player then
		local character = Player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp:IsA("BasePart") then
				local root = PlacementSnap.GetRootPart(target)
				if root then
					local R = radius or PlacementSnap.SNAP_RADIUS
					local station = FindNearestStation(target, R)

					if station then
						local grid = station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
						if grid and grid:IsA("Folder") then
							local nearestCell: BasePart? = nil
							local bestDist = math.huge
							for _, cell in ipairs(grid:GetDescendants()) do
								if cell:IsA("BasePart") then
									local d = (cell.Position - root.Position).Magnitude
									if d <= R and d < bestDist then
										bestDist = d
										nearestCell = cell
									end
								end
							end

							if nearestCell then
								local cellForward = nearestCell.CFrame.LookVector
								local playerForward = hrp.CFrame.LookVector

								local playerForwardFlat = Vector3.new(playerForward.X, 0, playerForward.Z).Unit
								local cellForwardFlat = Vector3.new(cellForward.X, 0, cellForward.Z).Unit

								local dotProduct = cellForwardFlat:Dot(playerForwardFlat)
								local crossProduct = cellForwardFlat:Cross(playerForwardFlat).Y
								local relativeAngle = math.atan2(crossProduct, dotProduct)

								rotationToUse = math.round(math.deg(relativeAngle) / 90) * 90
							end
						end
					end
				end
			end
		end
	end

	-- Try to find cells with calculated rotation
	local cells = PlacementSnap.FindNearestFreeFootprintOnSameStation(target, radius, rotationToUse)

	-- Only snap if we found the correct number of cells
	if cells and #cells == (fp.X * fp.Y) then
		PlacementSnap.SnapToCells(target, cells, true, Player, rotationToUse)
		PlacementSnap.BindAutoUnsnapHooks(target)
		return true
	end

	return false
end

-- Check if object is a placement cell
function PlacementSnap.IsPlacementCell(obj: Instance?): boolean
	return obj ~= nil
		and obj:IsA("BasePart")
		and obj.Parent ~= nil
		and obj.Parent.Name == CFG.PLACEMENT_GRID_NAME
end

-- Helper: Check if station has enough space
function PlacementSnap.HasAvailableSpace(station: Model, requiredFootprint: any): boolean
	return PlacementGrid.HasAvailableSpace(station, requiredFootprint)
end

-- Helper: Get free cell count
function PlacementSnap.GetFreeCellCount(station: Model): number
	return PlacementGrid.GetFreeCellCount(station)
end

-- Helper: Get total cell count
function PlacementSnap.GetTotalCellCount(station: Model): number
	return PlacementGrid.GetTotalCellCount(station)
end

-- Helper: Calculate player rotation relative to a cell (shared with GridVisualization)
function PlacementSnap.CalculatePlayerRotationRelativeToCell(playerCFrame: CFrame, cell: BasePart): number
	local cellForward = cell.CFrame.LookVector
	local playerForward = playerCFrame.LookVector

	local playerForwardFlat = Vector3.new(playerForward.X, 0, playerForward.Z).Unit
	local cellForwardFlat = Vector3.new(cellForward.X, 0, cellForward.Z).Unit

	local dotProduct = cellForwardFlat:Dot(playerForwardFlat)
	local crossProduct = cellForwardFlat:Cross(playerForwardFlat).Y
	local relativeAngle = math.atan2(crossProduct, dotProduct)

	return math.round(math.deg(relativeAngle) / 90) * 90
end

return PlacementSnap