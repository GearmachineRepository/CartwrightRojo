--!strict
--!optimize 2
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

--Modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local PhysicsModule = require(Modules:WaitForChild("PhysicsGroups"))
local PlacementSnap = require(Modules:WaitForChild("PlacementSnap"))
local CartAssembly = require(Modules:WaitForChild("CartAssembly"))
local UIDManager = require(Modules:WaitForChild("UIDManager"))
local GlobalNumbers = require(Modules:WaitForChild("GlobalNumbers"))
local OwnershipValidator = require(Modules:WaitForChild("ObjectValidator"))
local ObjectStateManager = require(Modules:WaitForChild("ObjectStateManager"))
local OwnershipManager = require(Modules:WaitForChild("OwnershipManager"))

-- Constants
local DRAG_TAG: string = "Drag"
local DRAG_ATTACHMENT_NAME: string = "DragAttachment"
local DRAG_NETWORK_DELAY: number = 0.35
local DEFAULT_DRAG_RESPONSIVENESS: number = 25 
local MASS_DIVISOR: number = 10
local REINSTALL_COOLDOWN = 0.6
local SNAP_RADIUS = GlobalNumbers.SNAP_DISTANCE  

-- Remote Events
local Events: Folder = ReplicatedStorage:WaitForChild("Events")
local DragEvents: Folder = Events:WaitForChild("DragEvents") :: Folder
local UpdateCameraPositionRemote: RemoteEvent = DragEvents:WaitForChild("UpdateCameraPosition") :: RemoteEvent
local DragObjectRemote: RemoteEvent = DragEvents:WaitForChild("DragObject") :: RemoteEvent

-- Player Data Storage
local PlayerData: {[Player]: {
	CFrameValue: CFrameValue?,
	DraggedParts: {[Instance]: RBXScriptConnection?}
}} = {}

local function CleanupDragState(Player: Player, Target: Instance)
	local Data = PlayerData[Player] 
	if not Data then return end

	local PhysicsPart: BasePart? = Target:IsA("Model") and (Target :: Model).PrimaryPart or (Target :: BasePart)
	if not PhysicsPart then return end

	local conn = Data.DraggedParts[Target]
	if conn then
		conn:Disconnect()
		Data.DraggedParts[Target] = nil
	end

	-- Use ObjectStateManager to clear state
	ObjectStateManager.ForceIdle(Target)
	OwnershipManager.UpdateInteractionTime(Target)
	PhysicsModule.SetToGroup(Target, "Static")

	local dragAtt = PhysicsPart:FindFirstChild("DragAttachment")
	if dragAtt then 
		dragAtt:Destroy() 
	end

	local ap = PhysicsPart:FindFirstChildOfClass("AlignPosition")
	if ap then 
		ap.Enabled = false 
		ap.Attachment0 = nil 
	end
	local ao = PhysicsPart:FindFirstChildOfClass("AlignOrientation")
	if ao then 
		ao.Enabled = false 
		ao.Attachment0 = nil 
	end

	-- Ensure object is truly stationary before releasing ownership
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
		
	-- Delayed ownership release with safety check
	task.delay(DRAG_NETWORK_DELAY, function()
		local currentState = ObjectStateManager.GetState(Target)
		-- Only release if idle (not grabbed by another player)
		if PhysicsPart:IsDescendantOf(workspace) 
			and not PhysicsPart.Anchored
			and currentState == "Idle" then
			pcall(function() 
				PhysicsPart:SetNetworkOwnershipAuto() 
			end)
		end
	end)
end

local function FindNearestOwnedCart(player: Player, nearPos: Vector3, maxDist: number): Model?
	local best, bestD
	for _, m in ipairs(workspace.Interactables:GetChildren()) do
		if m:IsA("Model") and m:HasTag("Cart") and m:GetAttribute("Owner") == player.UserId then
			local pp = m.PrimaryPart
			if pp then
				local d = (pp.Position - nearPos).Magnitude
				if d <= maxDist and (not bestD or d < bestD) then
					best, bestD = m, d
				end
			end
		end
	end
	return best
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
	
	-- Find nearest owned cart
	local NearestCart = FindNearestOwnedCart(Player, Root.Position, 30)
	if not NearestCart then return nil, nil end
	
	-- Find nearest anchor on that cart
	local NearestAnchor, AxleNumber = CartAssembly.findNearestWheelAnchor(
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

local function TryInstallWheelAtAnchor(player: Player, model: Model): boolean
	-- cooldown
	local t0 = model:GetAttribute("LastDetachTime")
	if typeof(t0) == "number" and (tick() - t0) < REINSTALL_COOLDOWN then return false end
	local root = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart") 
	if not root then return false end
	local cart = FindNearestOwnedCart(player, root.Position, 20) 
	if not cart then return false end

	local lastCartUID = model:GetAttribute("LastDetachCartUID")
	if typeof(lastCartUID) == "string" and lastCartUID ~= "" then
		local thisCartUID = UIDManager.ensureModelUID(cart)
		if thisCartUID ~= lastCartUID and typeof(t0)=="number" and (tick()-t0) < (REINSTALL_COOLDOWN*2) then
			return false
		end
	end

	local anchor, axleNum = CartAssembly.findNearestWheelAnchor(cart, root.Position, SNAP_RADIUS)
	if not anchor or not axleNum then return false end

	return CartAssembly.installWheelAttachmentAtAnchor(cart, model, anchor, axleNum)
end

-- true if player is allowed to drag this target
local function CanPlayerDrag(player: Player, target: Instance): boolean
	local validation = OwnershipValidator.CanDrag(player, target)
	if not validation.IsValid then
		return false
	end

	if not CollectionService:HasTag(target, "Drag") then
		return false
	end

	return true
end

-- Initialize Player Data
local function InitializePlayerData(Player: Player): ()
	local CFrameValue: CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Name = "CameraPosition"
	CFrameValue.Parent = Player

	PlayerData[Player] = {
		CFrameValue = CFrameValue,
		DraggedParts = {}
	}

	Player.CharacterAdded:Connect(function(Character)
		local HumanoidRootPart = Character:WaitForChild("HumanoidRootPart", 10)
		if HumanoidRootPart then
			PhysicsModule.SetToGroup(Character, "Characters")
		else
			Player:Kick("Took too long to load.")
		end
	end)
end

-- Setup Drag Components for Parts with Drag Tag
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

		-- Ensure model has a PrimaryPart
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

-- Start Dragging Function
local function StartDragging(Player: Player, Target: Instance): ()
	if not CanPlayerDrag(Player, Target) then return end

	local Data = PlayerData[Player]
	if not Data or not Data.CFrameValue then return end

	-- Check state transition validity
	if not ObjectStateManager.CanTransition(Target, "BeingDragged") then
		warn("[DragServer] Cannot transition to BeingDragged state")
		return
	end

	if Target:GetAttribute("SnappedToGrid") then
		PlacementSnap.UnsnapFromPlacementCell(Target)
	end

	if Target:IsA("Model") and Target:GetAttribute("PartType") == "Wheel" then
		local rootPart = Target.PrimaryPart or Target:FindFirstChildWhichIsA("BasePart")
		if rootPart then
			local cart = FindNearestOwnedCart(Player, rootPart.Position, 30)
			if cart and cart:GetAttribute("Owner") == Player.UserId then
				if CartAssembly.detachWheelAttachment(cart, Target) then
					Target:SetAttribute("LastDetachTime", tick())
					Target:SetAttribute("LastDetachCartUID", UIDManager.ensureModelUID(cart))
					Target:SetAttribute("LastDetachAnchor", Target:GetAttribute("AnchorName"))
				end
			end
		end
	end

	-- Set state using ObjectStateManager
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

		local UpdateConnection: RBXScriptConnection = RunService.Heartbeat:Connect(function()
			if Data.CFrameValue then
				local TargetCFrame: CFrame = Data.CFrameValue.Value
				AlignPosition.Position = TargetCFrame.Position
				AlignOrientation.CFrame = TargetCFrame
			end
		end)

		local ProximityUpdateConnection do
			ProximityUpdateConnection = RunService.Heartbeat:Connect(function()
				if not Target.Parent or ObjectStateManager.GetState(Target) ~= "BeingDragged" then
					ProximityUpdateConnection:Disconnect()
					return
				end
				
				local _, AnchorDistance = GetNearestAnchor(Player, Target)
				local GridDistance = GetNearestGridDistance(Target)
				
				-- Set attribute for client visual feedback
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
			end)
		end 

		Data.DraggedParts[Target] = UpdateConnection
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

	-- Check if already snapped (from real-time snapping during drag)
	local FinalState = ObjectStateManager.GetState(Target)
	if FinalState == "SnappedToGrid" then
		return
	end

	-- DISTANCE-BASED PRIORITY: Check both anchor and grid distances
	local NearestAnchor, AnchorDistance = GetNearestAnchor(Player, Target)
	local GridDistance = GetNearestGridDistance(Target)
	
	local SnapSuccess = false
	
	-- Try closest option first
	if AnchorDistance and GridDistance then
		if AnchorDistance < GridDistance then
			-- Anchor is closer
			SnapSuccess = TryInstallWheelAtAnchor(Player, Target)
			if not SnapSuccess then
				-- Fallback to grid
				SnapSuccess = PlacementSnap.TrySnapNearestFootprint(Target, SNAP_RADIUS, Player)
			end
		else
			-- Grid is closer
			SnapSuccess = PlacementSnap.TrySnapNearestFootprint(Target, SNAP_RADIUS, Player)
			if not SnapSuccess then
				-- Fallback to anchor
				SnapSuccess = TryInstallWheelAtAnchor(Player, Target)
			end
		end
	elseif AnchorDistance then
		-- Only anchor available
		SnapSuccess = TryInstallWheelAtAnchor(Player, Target)
	elseif GridDistance then
		-- Only grid available
		SnapSuccess = PlacementSnap.TrySnapNearestFootprint(Target, SNAP_RADIUS, Player)
	end

	-- Handle ground drop if nothing snapped
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

-- Stop All Dragging for Player
local function StopAllDragging(Player: Player): ()
	local Data = PlayerData[Player]
	if not Data then return end

	-- Create a copy of the keys to avoid modifying table while iterating
	local PartsToStop: {Instance} = {}
	for Part: Instance in pairs(Data.DraggedParts) do
		table.insert(PartsToStop, Part)
	end

	-- Stop dragging all parts
	for _, Part: Instance in pairs(PartsToStop) do
		StopDragging(Player, Part)
	end
end

-- Cleanup Player Data
local function CleanupPlayerData(Player: Player): ()
	local Data = PlayerData[Player]
	if not Data then return end

	-- Stop all drag updates and clear dragged parts
	for PhysicsObject: Instance, Connection: RBXScriptConnection? in pairs(Data.DraggedParts) do
		if Connection then
			Connection:Disconnect()
		end
		StopDragging(Player, PhysicsObject)
	end

	-- Clean up CFrameValue
	if Data.CFrameValue then
		Data.CFrameValue:Destroy()
	end

	PlayerData[Player] = nil
end

-- Remote Event Handlers
UpdateCameraPositionRemote.OnServerEvent:Connect(function(Player: Player, CameraPosition: CFrame)
	local Data = PlayerData[Player]
	if Data and Data.CFrameValue then
		Data.CFrameValue.Value = CameraPosition
	end
end)

DragObjectRemote.OnServerEvent:Connect(function(Player: Player, Part: Instance?, Status: boolean)
	-- Handle stop all dragging (when Part is nil and Status is false)
	if not Part and not Status then
		StopAllDragging(Player)
		return
	end

	-- Validate part exists and has drag tag
	if not Part or not Part.Parent then return end
	if not CollectionService:HasTag(Part, DRAG_TAG) then return end

	if Status then
		StartDragging(Player, Part)
	else
		StopDragging(Player, Part)
	end
end)

-- Collection Service Events
CollectionService:GetInstanceAddedSignal(DRAG_TAG):Connect(SetupDragComponents)

-- Setup existing tagged parts
for _, Target: Instance in pairs(CollectionService:GetTagged(DRAG_TAG)) do
	if Target:IsA("BasePart") or Target:IsA("Model") then
		SetupDragComponents(Target)
	end
end

-- Player Connection Events
Players.PlayerAdded:Connect(InitializePlayerData)
Players.PlayerRemoving:Connect(CleanupPlayerData)

-- Initialize existing players
for _, Player: Player in pairs(Players:GetPlayers()) do
	InitializePlayerData(Player)
end