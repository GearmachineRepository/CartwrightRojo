--!strict
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Modules = script.Parent
local PlacementFootprint = require(Modules:WaitForChild("PlacementFootprint"))
local PlacementGrid = require(Modules:WaitForChild("PlacementGrid"))
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))
local Maid = require(Modules:WaitForChild("Maid"))

local PlacementSnap = {
	SNAP_RADIUS = GeneralUtil.SNAP_DISTANCE,
}

local CFG = {
	PLACEMENT_GRID_NAME = "PlacementGrid",
	PLACEMENT_WELD_NAME = "PlacementWeld",
	PLACEMENT_CELL_REF_NAME = "PlacementCell",
	ORIGINAL_PARENT_REF_NAME = "OriginalParent",
	DRAG_TAG = "Drag",
	ALIGN_ORIENTATION = true,
}

local CELL_REFS_FOLDER_NAME = "PlacementCells"

local function IsAncestorOf(InstanceA: Instance, InstanceB: Instance): boolean
	return InstanceB:IsDescendantOf(InstanceA)
end

function PlacementSnap.GetRootPart(Inst: Instance): BasePart?
	if Inst:IsA("BasePart") then return Inst end
	if Inst:IsA("Model") then
		local ModelInstance = Inst :: Model
		return ModelInstance.PrimaryPart or ModelInstance:FindFirstChildWhichIsA("BasePart")
	end
	return nil
end

local function EnsurePrimary(ModelInstance: Model): BasePart?
	if ModelInstance.PrimaryPart and ModelInstance.PrimaryPart:IsDescendantOf(ModelInstance) then
		return ModelInstance.PrimaryPart
	end
	for _, Descendant in ipairs(ModelInstance:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			ModelInstance.PrimaryPart = Descendant
			return Descendant
		end
	end
	return nil
end

local function GetCellRef(Target: Instance): ObjectValue?
	return Target:FindFirstChild(CFG.PLACEMENT_CELL_REF_NAME) :: ObjectValue
end

local function SetCellRef(Target: Instance, Cell: BasePart?)
	local Ref: any = GetCellRef(Target)
	if Cell then
		if not Ref then
			local NewRef = Instance.new("ObjectValue")
			NewRef.Name = CFG.PLACEMENT_CELL_REF_NAME
			NewRef.Parent = Target
			Ref = NewRef
		end
		Ref.Value = Cell
	else
		if Ref then
			Ref:Destroy()
		end
	end
end

local function GetOriginalParentRef(Target: Instance): ObjectValue?
	return Target:FindFirstChild(CFG.ORIGINAL_PARENT_REF_NAME) :: ObjectValue
end

local function SetOriginalParentRef(Target: Instance, ParentInst: Instance?)
	local Ref = GetOriginalParentRef(Target)
	if ParentInst then
		if not Ref then
			Ref = Instance.new("ObjectValue")
			Ref.Name = CFG.ORIGINAL_PARENT_REF_NAME
			Ref.Parent = Target
		end
		Ref.Value = ParentInst
	else
		if Ref then
			Ref:Destroy()
		end
	end
end

local function GetOrCreateCellsFolder(Target: Instance): Folder
	local FolderInstance = Target:FindFirstChild(CELL_REFS_FOLDER_NAME)
	if not FolderInstance then
		FolderInstance = Instance.new("Folder")
		FolderInstance.Name = CELL_REFS_FOLDER_NAME
		FolderInstance.Parent = Target
	end
	return FolderInstance :: Folder
end

local function ClearCellsFolder(Target: Instance)
	local FolderInstance = Target:FindFirstChild(CELL_REFS_FOLDER_NAME)
	if FolderInstance then
		for _, Child in ipairs(FolderInstance:GetChildren()) do
			Child:Destroy()
		end
	end
end

local function FindNearestStation(Target: Instance, _: number): Model?
	local Root = PlacementSnap.GetRootPart(Target)
	if not Root then return nil end

	local Ref = GetCellRef(Target)
	if Ref and Ref.Value and Ref.Value:IsA("BasePart") then
		return PlacementGrid.GetStationFromCell(Ref.Value)
	end

	local BestDist = math.huge
	local Station: Model? = nil

	for _, Folder in ipairs(Workspace:GetDescendants()) do
		if Folder:IsA("Folder") and Folder.Name == CFG.PLACEMENT_GRID_NAME then
			local Par = Folder.Parent
			if Par and Par:IsA("Model") then
				local Pp = EnsurePrimary(Par)
				if Pp then
					local Distance = (Pp.Position - Root.Position).Magnitude
					if Distance < BestDist then
						BestDist = Distance
						Station = Par
					end
				end
			end
		end
	end

	return Station
end

function PlacementSnap.FindNearestFreeFootprintOnSameStation(
	Target: Instance,
	Radius: number?,
	RotationDegrees: number?
): {BasePart}?
	local Root = PlacementSnap.GetRootPart(Target)
	if not Root then return nil end

	local BaseFp = PlacementFootprint.GetFootprint(Target)
	local Fp = PlacementFootprint.ApplyRotation(BaseFp, RotationDegrees)
	local Need = PlacementFootprint.GetCellCount(Fp)
	local RadiusToUse = Radius or PlacementSnap.SNAP_RADIUS

	local Station = FindNearestStation(Target, RadiusToUse)
	if not Station then return nil end

	local Index = PlacementGrid.BuildIndex(Station)
	if not Index then return nil end

	table.sort(Index.all, function(CellA, CellB)
		local Da = (CellA.cell.Position - Root.Position).Magnitude
		local Db = (CellB.cell.Position - Root.Position).Magnitude
		return Da < Db
	end)

	for _, Meta in ipairs(Index.all) do
		local Dist = (Meta.cell.Position - Root.Position).Magnitude
		if Dist <= RadiusToUse then
			local Patch = PlacementGrid.FindFootprintCells(Index, Meta.area, Meta.x, Meta.y, Fp)
			if Patch and #Patch == Need then
				return Patch
			end
		end
	end

	return nil
end

function PlacementSnap.DestroyPlacementWeldsFor(Root: BasePart)
	for _, Ch in ipairs(Root:GetChildren()) do
		if Ch:IsA("WeldConstraint") and Ch.Name == CFG.PLACEMENT_WELD_NAME then
			Ch:Destroy()
		end
	end
end

function PlacementSnap.UnsnapFromPlacementCell(Target: Instance, _Player: Player?)
	local Root = PlacementSnap.GetRootPart(Target)
	if not Root then return end

	local Station: Model? = nil
	local StationWasAnchored = false
	local Ref = GetCellRef(Target)
	if Ref and Ref.Value and Ref.Value:IsA("BasePart") then
		Station = PlacementGrid.GetStationFromCell(Ref.Value)
		if Station and Station.PrimaryPart then
			StationWasAnchored = Station.PrimaryPart.Anchored
			if not StationWasAnchored then
				Station.PrimaryPart.Anchored = true
			end
		end
	end

	PlacementSnap.DestroyPlacementWeldsFor(Root)

	local CellsFolder = Target:FindFirstChild(CELL_REFS_FOLDER_NAME)
	if CellsFolder then
		for _, Ov in ipairs(CellsFolder:GetChildren()) do
			if Ov:IsA("ObjectValue") and Ov.Value and Ov.Value:IsA("BasePart") then
				PlacementGrid.MarkCell(Ov.Value, false)
			end
		end
		CellsFolder:ClearAllChildren()
	end

	if Ref and Ref.Value and Ref.Value:IsA("BasePart") then
		PlacementGrid.MarkCell(Ref.Value, false)
	end

	local Op = GetOriginalParentRef(Target)
	if Op and Op.Value then
		Target.Parent = Op.Value
	end

	SetCellRef(Target, nil)
	SetOriginalParentRef(Target, nil)
	ObjectStateManager.ForceIdle(Target)

	if not CollectionService:HasTag(Target, CFG.DRAG_TAG) then
		CollectionService:AddTag(Target, CFG.DRAG_TAG)
	end

	pcall(function()
		if Root:IsDescendantOf(Workspace) and not Root.Anchored then
			Root:SetNetworkOwnershipAuto()
		end
	end)

	if Station and Station.PrimaryPart and not StationWasAnchored then
		task.defer(function()
			if Station.PrimaryPart then
				Station.PrimaryPart.Anchored = false
			end
		end)
	end
end

function PlacementSnap.SnapToCells(
	Target: Instance,
	Cells: any,
	AlignOrientation: boolean?,
	Player: Player?,
	ManualRotationDegrees: number?
)
	if typeof(Cells) == "Instance" and Cells:IsA("BasePart") then
		Cells = { Cells }
	elseif typeof(Cells) ~= "table" then
		warn("[PlacementSnap] SnapToCells expected BasePart or {BasePart}, got:", typeof(Cells))
		return
	end
	if #Cells == 0 then return end

	for _, Cell in ipairs(Cells) do
		if not PlacementGrid.IsCellAvailable(Cell) then
			warn("[PlacementSnap] Cannot snap - one or more cells already occupied")
			return
		end
	end

	local Root = PlacementSnap.GetRootPart(Target)
	if not Root then return end

	local FirstCell: BasePart = Cells[1]
	local Station = PlacementGrid.GetStationFromCell(FirstCell)
	if not (Station and Station:IsA("Model")) then return end
	EnsurePrimary(Station)
	if Target == Station or IsAncestorOf(Target, FirstCell) then return end

	if Target:GetAttribute("BeingDragged") then
		warn("[PlacementSnap] Object was still BeingDragged, clearing state before snap")
		ObjectStateManager.ForceIdle(Target)
	end

	PlacementSnap.DestroyPlacementWeldsFor(Root)

	if not GetOriginalParentRef(Target) then
		SetOriginalParentRef(Target, Target.Parent)
	end

	local Ap = Root:FindFirstChildOfClass("AlignPosition")
	if Ap then
		Ap.Enabled = false
		Ap.Attachment0 = nil
	end
	local Ao = Root:FindFirstChildOfClass("AlignOrientation")
	if Ao then
		Ao.Enabled = false
		Ao.Attachment0 = nil
	end
	Root.AssemblyLinearVelocity = Vector3.zero
	Root.AssemblyAngularVelocity = Vector3.zero
	Root.Anchored = false

	local Sum = Vector3.zero
	for _, Cell in ipairs(Cells) do
		Sum += Cell.Position
	end
	local CenterPos = Sum / #Cells

	local DoOrient = (AlignOrientation ~= nil) and AlignOrientation or CFG.ALIGN_ORIENTATION
	local TargetCF
	if DoOrient then
		local BaseCF = CFrame.new(CenterPos) * (FirstCell.CFrame - FirstCell.Position)

		if Player and not ManualRotationDegrees then
			local Character = Player.Character
			if Character then
				local Hrp = Character:FindFirstChild("HumanoidRootPart")
				if Hrp and Hrp:IsA("BasePart") then
					local CellForward = FirstCell.CFrame.LookVector
					local PlayerForward = Hrp.CFrame.LookVector

					local PlayerForwardFlat = Vector3.new(PlayerForward.X, 0, PlayerForward.Z).Unit
					local CellForwardFlat = Vector3.new(CellForward.X, 0, CellForward.Z).Unit

					local DotProduct = CellForwardFlat:Dot(PlayerForwardFlat)
					local CrossProduct = CellForwardFlat:Cross(PlayerForwardFlat).Y
					local RelativeAngle = math.atan2(CrossProduct, DotProduct)

					local SnappedRelativeAngle = math.round(RelativeAngle / (math.pi/2)) * (math.pi/2)

					TargetCF = BaseCF * CFrame.Angles(0, SnappedRelativeAngle, 0)
				else
					TargetCF = BaseCF
				end
			else
				TargetCF = BaseCF
			end
		elseif ManualRotationDegrees then
			local ManualRotationRad = math.rad(ManualRotationDegrees)
			TargetCF = BaseCF * CFrame.Angles(0, ManualRotationRad, 0)
		else
			TargetCF = BaseCF
		end
	else
		TargetCF = CFrame.new(CenterPos)
	end

	local ItemHeight = 0
	if Target:IsA("Model") then
		local _, Size = Target:GetBoundingBox()
		ItemHeight = Size.Y
	elseif Target:IsA("BasePart") then
		ItemHeight = Target.Size.Y
	end

	local CellHeight = FirstCell.Size.Y
	local HeightOffset = ((CellHeight/2) + (ItemHeight / 2)) - CellHeight

	if Target:IsA("Model") then
		Target:PivotTo(TargetCF * CFrame.new(0, HeightOffset, 0))
	else
		Root.CFrame = TargetCF * CFrame.new(0, CellHeight, 0)
	end

	local Weld = Instance.new("WeldConstraint")
	Weld.Name = CFG.PLACEMENT_WELD_NAME
	Weld.Part0 = FirstCell
	Weld.Part1 = Root
	Weld.Parent = Root

	Target.Parent = FirstCell

	PlacementGrid.MarkCells(Cells, true)
	SetCellRef(Target, FirstCell)

	ClearCellsFolder(Target)
	local Folder = GetOrCreateCellsFolder(Target)
	for _, Cell in ipairs(Cells) do
		local Ov = Instance.new("ObjectValue")
		Ov.Name = "Cell"
		Ov.Value = Cell
		Ov.Parent = Folder
	end

	ObjectStateManager.SetState(Target, "SnappedToGrid")
	if Player then
		Target:SetAttribute("Owner", Player.UserId or Player:GetAttribute("Id"))
	end
	if not CollectionService:HasTag(Target, CFG.DRAG_TAG) then
		CollectionService:AddTag(Target, CFG.DRAG_TAG)
	end

	task.defer(function()
		if Root.Parent then
			Root.AssemblyLinearVelocity = Vector3.zero
			Root.AssemblyAngularVelocity = Vector3.zero
			pcall(function()
				Root:SetNetworkOwnershipAuto()
			end)
		end
	end)
end

function PlacementSnap.SnapToPlacementCell(
	_: Instance,
	Cell: BasePart,
	AlignOrientation: boolean?,
	Player: Player?,
	ManualRotationDegrees: number?
)
	if not Cell or not Cell:IsA("BasePart") then return end
	PlacementSnap.SnapToCells({Cell}, AlignOrientation, Player, ManualRotationDegrees)
end

function PlacementSnap.FindNearestFreeCellOnSameStation(Target: Instance, Radius: number?): BasePart?
	local Root = PlacementSnap.GetRootPart(Target)
	if not Root then return nil end

	local Station = FindNearestStation(Target, Radius or PlacementSnap.SNAP_RADIUS)
	if not Station then return nil end

	return PlacementGrid.FindNearestAvailableCell(Station, Root.Position, Radius or PlacementSnap.SNAP_RADIUS)
end

function PlacementSnap.BindAutoUnsnapHooks(Target: Instance): (() -> ())
	local HookMaid = Maid.new()

	local function ShouldUnsnap(): boolean
		if not Target.Parent then return true end
		if Target:IsDescendantOf(game:GetService("Players")) then return true end
		local Parent = Target.Parent
		if Parent:IsA("Backpack") or Parent:IsA("Tool") or Parent:IsA("Accessory") then return true end

		local CellRef = GetCellRef(Target)
		if CellRef and CellRef.Value then
			if not Target:IsDescendantOf(CellRef.Value) then
				return true
			end
		end
		return false
	end

	HookMaid:GiveTask(Target.AncestryChanged:Connect(function()
		if Target:GetAttribute("SnappedToGrid") and ShouldUnsnap() then
			PlacementSnap.UnsnapFromPlacementCell(Target)
		end
	end))

	HookMaid:GiveTask(Target:GetPropertyChangedSignal("Parent"):Connect(function()
		if Target:GetAttribute("SnappedToGrid") and ShouldUnsnap() then
			PlacementSnap.UnsnapFromPlacementCell(Target)
		end
	end))

	return function()
		HookMaid:Destroy()
	end
end

function PlacementSnap.TrySnapNearestFootprint(
	Target: Instance,
	Radius: number?,
	Player: Player?,
	ManualRotationDegrees: number?
): boolean
	local Fp = PlacementFootprint.GetFootprint(Target)

	local RotationToUse = ManualRotationDegrees
	if not RotationToUse and Player then
		local Character = Player.Character
		if Character then
			local Hrp = Character:FindFirstChild("HumanoidRootPart")
			if Hrp and Hrp:IsA("BasePart") then
				local Root = PlacementSnap.GetRootPart(Target)
				if Root then
					local RadiusToUse = Radius or PlacementSnap.SNAP_RADIUS
					local Station = FindNearestStation(Target, RadiusToUse)

					if Station then
						local Grid = Station:FindFirstChild(CFG.PLACEMENT_GRID_NAME)
						if Grid and Grid:IsA("Folder") then
							local NearestCell: BasePart? = nil
							local BestDist = math.huge
							for _, Cell in ipairs(Grid:GetDescendants()) do
								if Cell:IsA("BasePart") then
									local Distance = (Cell.Position - Root.Position).Magnitude
									if Distance <= RadiusToUse and Distance < BestDist then
										BestDist = Distance
										NearestCell = Cell
									end
								end
							end

							if NearestCell then
								local CellForward = NearestCell.CFrame.LookVector
								local PlayerForward = Hrp.CFrame.LookVector

								local PlayerForwardFlat = Vector3.new(PlayerForward.X, 0, PlayerForward.Z).Unit
								local CellForwardFlat = Vector3.new(CellForward.X, 0, CellForward.Z).Unit

								local DotProduct = CellForwardFlat:Dot(PlayerForwardFlat)
								local CrossProduct = CellForwardFlat:Cross(PlayerForwardFlat).Y
								local RelativeAngle = math.atan2(CrossProduct, DotProduct)

								RotationToUse = math.round(math.deg(RelativeAngle) / 90) * 90
							end
						end
					end
				end
			end
		end
	end

	local Cells = PlacementSnap.FindNearestFreeFootprintOnSameStation(Target, Radius, RotationToUse)

	if Cells and #Cells == (Fp.X * Fp.Y) then
		PlacementSnap.SnapToCells(Target, Cells, true, Player, RotationToUse)
		PlacementSnap.BindAutoUnsnapHooks(Target)
		return true
	end

	return false
end

function PlacementSnap.IsPlacementCell(Obj: Instance?): boolean
	return Obj ~= nil
		and Obj:IsA("BasePart")
		and Obj.Parent ~= nil
		and Obj.Parent.Name == CFG.PLACEMENT_GRID_NAME
end

function PlacementSnap.HasAvailableSpace(Station: Model, RequiredFootprint: any): boolean
	return PlacementGrid.HasAvailableSpace(Station, RequiredFootprint)
end

function PlacementSnap.GetFreeCellCount(Station: Model): number
	return PlacementGrid.GetFreeCellCount(Station)
end

function PlacementSnap.GetTotalCellCount(Station: Model): number
	return PlacementGrid.GetTotalCellCount(Station)
end

function PlacementSnap.CalculatePlayerRotationRelativeToCell(PlayerCFrame: CFrame, Cell: BasePart): number
	local CellForward = Cell.CFrame.LookVector
	local PlayerForward = PlayerCFrame.LookVector

	local PlayerForwardFlat = Vector3.new(PlayerForward.X, 0, PlayerForward.Z).Unit
	local CellForwardFlat = Vector3.new(CellForward.X, 0, CellForward.Z).Unit

	local DotProduct = CellForwardFlat:Dot(PlayerForwardFlat)
	local CrossProduct = CellForwardFlat:Cross(PlayerForwardFlat).Y
	local RelativeAngle = math.atan2(CrossProduct, DotProduct)

	return math.round(math.deg(RelativeAngle) / 90) * 90
end

return PlacementSnap