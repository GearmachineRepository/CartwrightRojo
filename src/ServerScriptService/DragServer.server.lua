--!strict
--!optimize 2
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local PhysicsModule = require(Modules:WaitForChild("PhysicsGroups"))
local PlacementSnap = require(Modules:WaitForChild("PlacementSnap"))
local CartAssembly = require(Modules:WaitForChild("CartAssembly"))
local UIDManager = require(Modules:WaitForChild("UIDManager"))
local GeneralUtil = require(Modules:WaitForChild("GeneralUtil"))
local OwnershipValidator = require(Modules:WaitForChild("ObjectValidator"))
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))
local OwnershipManager = require(Modules:WaitForChild("OwnershipManager"))
local Maid = require(Modules:WaitForChild("Maid"))

local DRAG_TAG: string = "Drag"
local DRAG_ATTACHMENT_NAME: string = "DragAttachment"
local DRAG_NETWORK_DELAY: number = 0.35
local DEFAULT_DRAG_RESPONSIVENESS: number = 25
local MASS_DIVISOR: number = 10
local REINSTALL_COOLDOWN = 0.6
local SNAP_RADIUS = GeneralUtil.SNAP_DISTANCE

local Events: Folder = ReplicatedStorage:WaitForChild("Events")
local DragEvents: Folder = Events:WaitForChild("DragEvents") :: Folder
local UpdateCameraPositionRemote: RemoteEvent = DragEvents:WaitForChild("UpdateCameraPosition") :: RemoteEvent
local DragObjectRemote: RemoteEvent = DragEvents:WaitForChild("DragObject") :: RemoteEvent
local DragBindable: BindableEvent = DragEvents:WaitForChild("SetObjectDragState") :: BindableEvent

type MaidType = typeof(Maid.new())
type PlayerData = {[Player]: {
	CFrameValue: CFrameValue?,
	DraggedParts: {[Instance]: MaidType},
	PlayerMaid: MaidType
}}

local PlayerData: PlayerData = {}

local function CleanupDragState(Player: Player, Target: Instance)
	local Data = PlayerData[Player]
	if not Data then return end

	local PhysicsPart: BasePart? = Target:IsA("Model") and (Target :: Model).PrimaryPart or (Target :: BasePart)
	if not PhysicsPart then return end

	local DragMaid = Data.DraggedParts[Target]
	if DragMaid then
		DragMaid:Destroy()
		Data.DraggedParts[Target] = nil
	end

	ObjectStateManager.ForceIdle(Target)
	OwnershipManager.UpdateInteractionTime(Target)
	PhysicsModule.SetToGroup(Target, "Static")

	local DragAtt = PhysicsPart:FindFirstChild("DragAttachment")
	if DragAtt then
		DragAtt:Destroy()
	end

	local AlignPos = PhysicsPart:FindFirstChildOfClass("AlignPosition")
	if AlignPos then
		AlignPos.Enabled = false
		AlignPos.Attachment0 = nil
	end
	local AlignOri = PhysicsPart:FindFirstChildOfClass("AlignOrientation")
	if AlignOri then
		AlignOri.Enabled = false
		AlignOri.Attachment0 = nil
	end

	if PhysicsPart:IsDescendantOf(workspace) then
		PhysicsPart.AssemblyLinearVelocity = Vector3.zero
		PhysicsPart.AssemblyAngularVelocity = Vector3.zero

		task.wait(0.05)

		if PhysicsPart:IsDescendantOf(workspace) then
			PhysicsPart.AssemblyLinearVelocity = Vector3.zero
			PhysicsPart.AssemblyAngularVelocity = Vector3.zero
			PhysicsModule.SetProperty(Target, "CanCollide", true)
		end
	end

	task.delay(DRAG_NETWORK_DELAY, function()
		local CurrentState = ObjectStateManager.GetState(Target)
		if PhysicsPart:IsDescendantOf(workspace)
			and not PhysicsPart.Anchored
			and CurrentState == "Idle" then
			pcall(function()
				PhysicsPart:SetNetworkOwnershipAuto()
			end)
		end
	end)
end

local function FindNearestOwnedCart(Player: Player, NearPos: Vector3, MaxDist: number): Model?
	local Best, BestDistance
	for _, Model in ipairs(workspace.Interactables:GetChildren()) do
		if Model:IsA("Model") and Model:HasTag("Cart") and Model:GetAttribute("Owner") == Player.UserId then
			local PrimaryPart = Model.PrimaryPart
			if PrimaryPart then
				local Distance = (PrimaryPart.Position - NearPos).Magnitude
				if Distance <= MaxDist and (not BestDistance or Distance < BestDistance) then
					Best, BestDistance = Model, Distance
				end
			end
		end
	end
	return Best
end

local function GetNearestGridDistance(Target: Instance): number?
	local Root = PlacementSnap.GetRootPart(Target)
	if not Root then return nil end

	local NearestCell = PlacementSnap.FindNearestFreeCellOnSameStation(Target, SNAP_RADIUS)
	if NearestCell then
		return (Root.Position - NearestCell.Position).Magnitude
	end

	return nil
end

local function GetNearestAnchor(Player: Player, Target: Instance): (Instance?, number?)
	if not Target:IsA("Model") then return nil, nil end
	if not Target:GetAttribute("PartType") then return nil, nil end

	local Root = PlacementSnap.GetRootPart(Target)
	if not Root then return nil, nil end

	local NearestCart = FindNearestOwnedCart(Player, Root.Position, 30)
	if not NearestCart then return nil, nil end

	local NearestAnchor, _ = CartAssembly.findNearestWheelAnchor(
		NearestCart,
		Root.Position,
		SNAP_RADIUS
	)

	if NearestAnchor then
		local AnchorPosition = NearestAnchor:IsA("Attachment")
			and NearestAnchor.WorldPosition
			or NearestAnchor.Position
		local Distance = (Root.Position - AnchorPosition).Magnitude
		return NearestAnchor, Distance
	end

	return nil, nil
end

local function TryInstallWheelAtAnchor(Player: Player, Model: Model): boolean
	local LastDetachTime = Model:GetAttribute("LastDetachTime")
	if typeof(LastDetachTime) == "number" and (tick() - LastDetachTime) < REINSTALL_COOLDOWN then return false end

	local Root = Model.PrimaryPart or Model:FindFirstChildWhichIsA("BasePart")
	if not Root then return false end

	local Cart = FindNearestOwnedCart(Player, Root.Position, 20)
	if not Cart then return false end

	local LastCartUID = Model:GetAttribute("LastDetachCartUID")
	if typeof(LastCartUID) == "string" and LastCartUID ~= "" then
		local ThisCartUID = UIDManager.EnsureModelUID(Cart)
		if ThisCartUID ~= LastCartUID and typeof(LastDetachTime) == "number" and (tick() - LastDetachTime) < (REINSTALL_COOLDOWN * 2) then
			return false
		end
	end

	local Anchor, AxleNum = CartAssembly.findNearestWheelAnchor(Cart, Root.Position, SNAP_RADIUS)
	if not Anchor or not AxleNum then return false end

	return CartAssembly.installWheelAttachmentAtAnchor(Cart, Model, Anchor, AxleNum)
end

local function CanPlayerDrag(Player: Player, Target: Instance): boolean
	local Validation = OwnershipValidator.CanDrag(Player, Target)
	if not Validation.IsValid then
		return false
	end

	if not CollectionService:HasTag(Target, "Drag") then
		return false
	end

	return true
end

local function SetupDragComponents(Target: Instance): ()
	PhysicsModule.SetToGroup(Target, "Static")

	if Target:IsA("BasePart") then
		local Part: BasePart = Target :: BasePart

		if not Part:FindFirstChildOfClass("AlignPosition") then
			local AlignPos: AlignPosition = Instance.new("AlignPosition")
			AlignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
			AlignPos.Enabled = false
			AlignPos.MaxForce = 40000
			AlignPos.Responsiveness = 25
			AlignPos.MaxVelocity = math.huge
			AlignPos.ApplyAtCenterOfMass = true
			AlignPos.Parent = Part
		end

		if not Part:FindFirstChildOfClass("AlignOrientation") then
			local AlignOri: AlignOrientation = Instance.new("AlignOrientation")
			AlignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
			AlignOri.Enabled = false
			AlignOri.MaxTorque = 40000
			AlignOri.Responsiveness = 25
			AlignOri.MaxAngularVelocity = math.huge
			AlignOri.Parent = Part
		end
	elseif Target:IsA("Model") then
		local Model: Model = Target :: Model

		if not Model.PrimaryPart then
			Model.PrimaryPart = Model:FindFirstChildWhichIsA("BasePart")
		end

		local PrimaryPart: BasePart? = Model.PrimaryPart
		if PrimaryPart then
			if not PrimaryPart:FindFirstChildOfClass("AlignPosition") then
				local AlignPos: AlignPosition = Instance.new("AlignPosition")
				AlignPos.Mode = Enum.PositionAlignmentMode.OneAttachment
				AlignPos.Enabled = false
				AlignPos.MaxForce = 40000
				AlignPos.Responsiveness = 25
				AlignPos.MaxVelocity = math.huge
				AlignPos.ApplyAtCenterOfMass = true
				AlignPos.Parent = PrimaryPart
			end

			if not PrimaryPart:FindFirstChildOfClass("AlignOrientation") then
				local AlignOri: AlignOrientation = Instance.new("AlignOrientation")
				AlignOri.Mode = Enum.OrientationAlignmentMode.OneAttachment
				AlignOri.Enabled = false
				AlignOri.MaxTorque = 40000
				AlignOri.Responsiveness = 25
				AlignOri.MaxAngularVelocity = math.huge
				AlignOri.Parent = PrimaryPart
			end
		end
	end
end

local function StartDragging(Player: Player, Target: Instance): ()
	if not CanPlayerDrag(Player, Target) then return end

	local Data = PlayerData[Player]
	if not Data or not Data.CFrameValue then return end

	if not ObjectStateManager.CanTransition(Target, "BeingDragged") then
		warn("[DragServer] Cannot transition to BeingDragged state")
		return
	end

	if Target:GetAttribute("SnappedToGrid") then
		PlacementSnap.UnsnapFromPlacementCell(Target)
	end

	if Target:IsA("Model") and Target:GetAttribute("PartType") == "Wheel" then
		local RootPart = Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart")
		if RootPart then
			local Cart = FindNearestOwnedCart(Player, RootPart.Position, 30)
			if Cart and Cart:GetAttribute("Owner") == Player.UserId then
				if CartAssembly.detachWheelAttachment(Cart, Target) then
					Target:SetAttribute("LastDetachTime", tick())
					Target:SetAttribute("LastDetachCartUID", UIDManager.EnsureModelUID(Cart))
					Target:SetAttribute("LastDetachAnchor", Target:GetAttribute("AnchorName"))
				end
			end
		end
	end

	Target:SetAttribute("LastDetachTime", tick())
	ObjectStateManager.SetState(Target, "BeingDragged", {DraggedBy = Player.Name})

	Target:SetAttribute("Owner", Player.UserId)
	OwnershipManager.TrackOwnership(Target, Player.UserId)

	local PhysicsPart: BasePart?
	if Target:IsA("Model") then
		PhysicsPart = (Target :: Model).PrimaryPart
	elseif Target:IsA("BasePart") then
		PhysicsPart = Target :: BasePart
	end

	if not PhysicsPart then return end

	PhysicsModule.SetProperty(Target, "Anchored", false)
	PhysicsModule.SetToGroup(Target, "Dragging")
	PhysicsPart:SetNetworkOwner(Player)

	local DragAttachment: Attachment = Instance.new("Attachment")
	DragAttachment.Name = DRAG_ATTACHMENT_NAME
	DragAttachment.Parent = PhysicsPart

	local AlignPosition: AlignPosition? = PhysicsPart:FindFirstChildOfClass("AlignPosition")
	local AlignOrientation: AlignOrientation? = PhysicsPart:FindFirstChildOfClass("AlignOrientation")

	if AlignPosition and AlignOrientation then
		local BaseMass: number = PhysicsPart.AssemblyMass
		local MassMultiplier: number = math.max(1, BaseMass / MASS_DIVISOR)
		local AdjustedResponsiveness: number = DEFAULT_DRAG_RESPONSIVENESS / MassMultiplier

		AdjustedResponsiveness = math.clamp(AdjustedResponsiveness, 1, 50)

		AlignPosition.Attachment0 = DragAttachment
		AlignPosition.Responsiveness = AdjustedResponsiveness
		AlignPosition.Enabled = true

		AlignOrientation.Attachment0 = DragAttachment
		AlignOrientation.Responsiveness = AdjustedResponsiveness
		AlignOrientation.Enabled = true

		local DragMaid = Maid.new()

		DragMaid:GiveTask(RunService.Heartbeat:Connect(function()
			if Data.CFrameValue then
				local TargetCFrame: CFrame = Data.CFrameValue.Value
				AlignPosition.Position = TargetCFrame.Position
				AlignOrientation.CFrame = TargetCFrame
			end

			if not Target.Parent or ObjectStateManager.GetState(Target) ~= "BeingDragged" then
				DragMaid:Destroy()
				return
			end

			local _, AnchorDistance = GetNearestAnchor(Player, Target)
			local GridDistance = GetNearestGridDistance(Target)

			if AnchorDistance and GridDistance then
				if AnchorDistance < GridDistance then
					Target:SetAttribute("ClosestSnapType", "Anchor")
				else
					Target:SetAttribute("ClosestSnapType", "Grid")
				end
			elseif AnchorDistance then
				Target:SetAttribute("ClosestSnapType", "Anchor")
			elseif GridDistance then
				Target:SetAttribute("ClosestSnapType", "Grid")
			else
				Target:SetAttribute("ClosestSnapType", nil)
			end
		end))

		Data.DraggedParts[Target] = DragMaid
	end
end

local function StopDragging(Player: Player, Target: Instance): ()
	local Data = PlayerData[Player]
	if not Data then return end

	local Root = PlacementSnap.GetRootPart(Target)
	if not Root then return end

	local CurrentState = ObjectStateManager.GetState(Target)
	if CurrentState == "BeingDragged" and Target:GetAttribute("DraggedBy") ~= Player.Name then
		return
	end

	if Player:GetAttribute("Carting") then
		task.delay(DRAG_NETWORK_DELAY, function()
			if Root:IsDescendantOf(workspace) and not Root.Anchored then
				pcall(function()
					Root:SetNetworkOwnershipAuto()
				end)
			end
		end)
		return
	end

	CleanupDragState(Player, Target)
	OwnershipManager.UpdateInteractionTime(Target)

	local FinalState = ObjectStateManager.GetState(Target)
	if FinalState == "SnappedToGrid" then
		return
	end

	local _, AnchorDistance = GetNearestAnchor(Player, Target)
	local GridDistance = GetNearestGridDistance(Target)

	local SnapSuccess = false

	if AnchorDistance and GridDistance then
		if AnchorDistance < GridDistance then
			SnapSuccess = TryInstallWheelAtAnchor(Player, Target)
			if not SnapSuccess then
				SnapSuccess = PlacementSnap.TrySnapNearestFootprint(Target, SNAP_RADIUS, Player)
			end
		else
			SnapSuccess = PlacementSnap.TrySnapNearestFootprint(Target, SNAP_RADIUS, Player)
			if not SnapSuccess then
				SnapSuccess = TryInstallWheelAtAnchor(Player, Target)
			end
		end
	elseif AnchorDistance then
		SnapSuccess = TryInstallWheelAtAnchor(Player, Target)
	elseif GridDistance then
		SnapSuccess = PlacementSnap.TrySnapNearestFootprint(Target, SNAP_RADIUS, Player)
	end

	if not SnapSuccess and Root:IsDescendantOf(workspace) and Player.Character then
		task.wait(0.1)

		local RayParams = RaycastParams.new()
		RayParams.FilterDescendantsInstances = {Target, Player.Character}
		RayParams.FilterType = Enum.RaycastFilterType.Exclude

		local RayOrigin = Root.Position
		local RayResult = workspace:Raycast(RayOrigin, Vector3.new(0, -50, 0), RayParams)

		if RayResult and (RayOrigin.Y - RayResult.Position.Y) > 5 then
			if Target:IsA("Model") then
				local CF = Target:GetPivot()
				Target:PivotTo(CF - Vector3.new(0, RayOrigin.Y - RayResult.Position.Y - 0.5, 0))
			else
				Root.Position = RayResult.Position + Vector3.new(0, 0.5, 0)
			end
		end
	end
end

local function StopAllDragging(Player: Player): ()
	local Data = PlayerData[Player]
	if not Data then return end

	local PartsToStop: {Instance} = {}
	for Part: Instance in pairs(Data.DraggedParts) do
		table.insert(PartsToStop, Part)
	end

	for _, Part: Instance in pairs(PartsToStop) do
		StopDragging(Player, Part)
	end
end

local function InitializePlayerData(Player: Player): ()
	local CFrameValue: CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Name = "CameraPosition"
	CFrameValue.Parent = Player

	local PlayerMaid = Maid.new()

	PlayerData[Player] = {
		CFrameValue = CFrameValue,
		DraggedParts = {},
		PlayerMaid = PlayerMaid
	}

	PlayerMaid:GiveTask(Player.CharacterAdded:Connect(function(Character)
		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
		if HumanoidRootPart then
			PhysicsModule.SetToGroup(Character, "Characters")
		else
			Player:Kick("Took too long to load.")
		end
	end))
end

local function CleanupPlayerData(Player: Player): ()
	local Data = PlayerData[Player]
	if not Data then return end

	for PhysicsObject: Instance, DragMaid: MaidType in pairs(Data.DraggedParts) do
		DragMaid:Destroy()
		StopDragging(Player, PhysicsObject)
	end

	if Data.CFrameValue then
		Data.CFrameValue:Destroy()
	end

	Data.PlayerMaid:Destroy()

	PlayerData[Player] = nil
end

UpdateCameraPositionRemote.OnServerEvent:Connect(function(Player: Player, CameraPosition: CFrame)
	local Data = PlayerData[Player]
	if Data and Data.CFrameValue then
		Data.CFrameValue.Value = CameraPosition
	end
end)

DragObjectRemote.OnServerEvent:Connect(function(Player: Player, Part: Instance?, Status: boolean)
	if not Part and not Status then
		StopAllDragging(Player)
		return
	end

	if not Part or not Part.Parent then return end
	if not CollectionService:HasTag(Part, DRAG_TAG) then return end

	if Status then
		StartDragging(Player, Part)
	else
		StopDragging(Player, Part)
	end
end)

DragBindable.Event:Connect(function(Player: Players, Object: Instance, State: boolean)
	if Player and Object then
		if not State then
			StopDragging(Player, Object)
		end
	end
end)

CollectionService:GetInstanceAddedSignal(DRAG_TAG):Connect(SetupDragComponents)

for _, Target: Instance in pairs(CollectionService:GetTagged(DRAG_TAG)) do
	if Target:IsA("BasePart") or Target:IsA("Model") then
		SetupDragComponents(Target)
	end
end

Players.PlayerAdded:Connect(InitializePlayerData)
Players.PlayerRemoving:Connect(CleanupPlayerData)

for _, Player: Player in pairs(Players:GetPlayers()) do
	InitializePlayerData(Player)
end