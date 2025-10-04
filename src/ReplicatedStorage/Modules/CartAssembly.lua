--!strict
local CartAssembly = {}

local UIDManager = require(script.Parent:WaitForChild("UIDManager"))
local ObjectValidator = require(script.Parent:WaitForChild("ObjectValidator"))

local MAX_WHEEL_SIZE_RATIO = 1.3

function CartAssembly.getWagon(Cart: Model): Model?
	local Wagon = Cart:FindFirstChild("Wagon")
	return (Wagon and Wagon:IsA("Model")) and Wagon or nil
end

function CartAssembly.getWagonRoot(Cart: Model): BasePart?
	local Wagon = CartAssembly.getWagon(Cart)
	 if not Wagon then return nil end
	local WagonRoot = Wagon:FindFirstChild("WagonRoot")
	return (WagonRoot and WagonRoot:IsA("BasePart")) and WagonRoot or nil
end

local function GetWheelDiameter(WheelModel: Model): number
	local _, Size = WheelModel:GetBoundingBox()
	return math.max(Size.X, Size.Z)
end

local function GetInstalledWheelSizes(Cart: Model): {number}
	local Sizes = {}
	for _, Descendant in ipairs(Cart:GetDescendants()) do
		if Descendant:IsA("Model") and Descendant:GetAttribute("PartType") == "Wheel" then
			local Diameter = GetWheelDiameter(Descendant)
			table.insert(Sizes, Diameter)
		end
	end
	return Sizes
end

local function IsWheelSizeCompatible(Cart: Model, NewWheelDiameter: number): boolean
	local ExistingSizes = GetInstalledWheelSizes(Cart)
	if #ExistingSizes == 0 then
		return true
	end
	for _, ExistingDiameter in ipairs(ExistingSizes) do
		local Larger = math.max(NewWheelDiameter, ExistingDiameter)
		local Smaller = math.min(NewWheelDiameter, ExistingDiameter)
		local Ratio = Larger / Smaller
		if Ratio > MAX_WHEEL_SIZE_RATIO then
			return false
		end
	end
	return true
end

local function GetWheelsFolder(Cart: Model): Instance?
	local Wagon = CartAssembly.getWagon(Cart)
	return Wagon and Wagon:FindFirstChild("Wheels") or nil
end

local function GetSpinByNumber(Cart: Model, AxleNumber: number): BasePart?
	local WheelsFolder = GetWheelsFolder(Cart)
	if not WheelsFolder then return nil end
	local Spin = WheelsFolder:FindFirstChild("Spin"..tostring(AxleNumber)) or WheelsFolder:FindFirstChild("Spin"..AxleNumber) or WheelsFolder:FindFirstChild("Spin")
	return (Spin and Spin:IsA("BasePart")) and Spin or nil
end

local function GetMotorByNumber(Cart: Model, AxleNumber: number): Motor6D?
	local WagonRoot = CartAssembly.getWagonRoot(Cart)
	if not WagonRoot then return nil end
	local Motor = WagonRoot:FindFirstChild("WheelMotor"..tostring(AxleNumber)) or WagonRoot:FindFirstChild("WheelMotor"..AxleNumber) or WagonRoot:FindFirstChild("WheelMotor")
	return (Motor and Motor:IsA("Motor6D")) and Motor or nil
end

local function AttachmentCF(AttachmentInstance: Attachment): CFrame
	local Parent = AttachmentInstance.Parent
	return (Parent and Parent:IsA("BasePart")) and (Parent.CFrame * AttachmentInstance.CFrame) or CFrame.new()
end

local function AnchorCF(Inst: Instance): CFrame
	local CF = Inst:IsA("Attachment") and AttachmentCF(Inst) or (Inst :: BasePart).CFrame
	local Offset = Inst:GetAttribute("LocalOffset")
	if typeof(Offset)=="Vector3" then 
		CF = CF * CFrame.new(Offset) 
	end
	return CF
end

local function SetAnchorOccupant(Anchor: Instance, UID: string?)
	Anchor:SetAttribute("OccupantUID", UID)
end

local function GetAnchorOccupant(Anchor: Instance): string?
	return Anchor:GetAttribute("OccupantUID")
end

local function ResolveAxleNumberFromAnchor(AnchorInstance: Instance): number
	local AxleAttribute = AnchorInstance:GetAttribute("AxleNumber")
	if typeof(AxleAttribute)=="number" and AxleAttribute>=1 then 
		return AxleAttribute 
	end
	local NumberMatch = tostring(AnchorInstance.Name):match("(%d+)")
	return NumberMatch and tonumber(NumberMatch) or 1
end

function CartAssembly.CountWheelsOnAnchors(Cart: Model): number
	local Wagon = CartAssembly.getWagon(Cart)
	if not Wagon then return 0 end
	
	local AnchorsFolder = Wagon:FindFirstChild("Anchors")
	if not AnchorsFolder or not AnchorsFolder:IsA("Folder") then return 0 end
	
	local WheelCount = 0
	for _, Anchor in ipairs(AnchorsFolder:GetChildren()) do
		if (Anchor:IsA("Attachment") or Anchor:IsA("BasePart")) and Anchor.Name:match("^Wheel") then
			local OccupantUID = GetAnchorOccupant(Anchor)
			if OccupantUID and OccupantUID ~= "" then
				WheelCount = WheelCount + 1
			end
		end
	end
	
	return WheelCount
end

function CartAssembly.findNearestWheelAnchor(Cart: Model, NearPos: Vector3, Radius: number): (Instance?, number?)
	local Wagon = CartAssembly.getWagon(Cart)
	 if not Wagon then return nil, nil end
	local AnchorsFolder = Wagon:FindFirstChild("Anchors")
	if not AnchorsFolder or not AnchorsFolder:IsA("Folder") then return nil, nil end
	
	local BestAnchor: Instance? = nil
	local BestDistance = math.huge
	local BestAxle: number? = nil
	
	for _, Anchor in ipairs(AnchorsFolder:GetChildren()) do
		if (Anchor:IsA("Attachment") or Anchor:IsA("BasePart")) and Anchor.Name:match("^Wheel") then
			local Distance = (AnchorCF(Anchor).Position - NearPos).Magnitude
			if Distance <= Radius and Distance < BestDistance then
				BestAnchor = Anchor
				BestDistance = Distance
				BestAxle = ResolveAxleNumberFromAnchor(Anchor)
			end
		end
	end
	return BestAnchor, BestAxle
end

function CartAssembly.installWheelAttachmentAtAnchor(Cart: Model, WheelModel: Model, Anchor: Instance, AxleNumber: number, Player: Player?): boolean
	if Player then
		local Validation = ObjectValidator.CanAttachWheel(Player, Cart, WheelModel)
		if not Validation.IsValid then
			warn("[CartAssembly]", Validation.Reason)
			return false
		end
	end
	
	local Spin = GetSpinByNumber(Cart, AxleNumber)
	if not Spin then return false end
	local Motor = GetMotorByNumber(Cart, AxleNumber)
	if not Motor then return false end

	local WheelUID = UIDManager.ensureModelUID(WheelModel)
	local Occupant = GetAnchorOccupant(Anchor)
	if Occupant and Occupant ~= WheelUID then return false end

	if not WheelModel.PrimaryPart then
		local AnyPart = WheelModel:FindFirstChildWhichIsA("BasePart")
		if not AnyPart then return false end
		WheelModel.PrimaryPart = AnyPart
	end
	
	local NewWheelDiameter = GetWheelDiameter(WheelModel)
	if not IsWheelSizeCompatible(Cart, NewWheelDiameter) then
		warn("[CartAssembly] Wheel size incompatible with existing wheels")
		return false
	end
	
	local WheelsFolder = GetWheelsFolder(Cart)
	if not WheelsFolder then return false end
	WheelModel.Parent = WheelsFolder
	WheelModel:PivotTo(AnchorCF(Anchor))

	local Root = WheelModel.PrimaryPart :: BasePart
	local ExistingWeld: WeldConstraint? = nil
	for _, Child in ipairs(Spin:GetChildren()) do
		if Child:IsA("WeldConstraint") and ((Child.Part0==Spin and Child.Part1==Root) or (Child.Part1==Spin and Child.Part0==Root)) then
			ExistingWeld = Child
			break
		end
	end
	if not ExistingWeld then
		local Weld = Instance.new("WeldConstraint")
		Weld.Name = "WheelAttachWeld"
		Weld.Part0 = Spin
		Weld.Part1 = Root
		Weld.Parent = Spin
	end

	if Motor.Part1 ~= Spin then 
		Motor.Part1 = Spin 
	end
	Motor.C1 = CFrame.new()

	Spin.Anchored = false
	for _, Descendant in ipairs(WheelModel:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			Descendant.Anchored = false
		end
	end

	SetAnchorOccupant(Anchor, WheelUID)
	WheelModel:SetAttribute("AxleNumber", AxleNumber)
	WheelModel:SetAttribute("AnchorName", Anchor.Name)

	return true
end

function CartAssembly.detachWheelAttachment(Cart: Model, WheelModel: Model): boolean
	local AxleNumber = tonumber(WheelModel:GetAttribute("AxleNumber")) or 1
	local Spin = GetSpinByNumber(Cart, AxleNumber); if not Spin then return false end
	local Root = (WheelModel.PrimaryPart or WheelModel:FindFirstChildWhichIsA("BasePart")) :: BasePart?
	if not Root then return false end

	local Weld: WeldConstraint? = nil
	for _, Child in ipairs(Spin:GetChildren()) do
		if Child:IsA("WeldConstraint") and ((Child.Part0==Spin and Child.Part1==Root) or (Child.Part1==Spin and Child.Part0==Root)) then
			Weld = Child
			break
		end
	end
	if not Weld then return false end
	
	-- Stabilize the cart chassis while we break the constraint
	local WagonRoot = CartAssembly.getWagonRoot(Cart)
	local prevAnchored: boolean? = WagonRoot and WagonRoot.Anchored
	if WagonRoot then WagonRoot.Anchored = true end

	Root.Anchored = true
	Weld:Destroy()

	local Wagon = CartAssembly.getWagon(Cart)
	if Wagon then
		local AnchorsFolder = Wagon:FindFirstChild("Anchors")
		if AnchorsFolder then
			local AnchorName = WheelModel:GetAttribute("AnchorName")
			local AnchorInstance = AnchorName and AnchorsFolder:FindFirstChild(tostring(AnchorName))
			if AnchorInstance then
				SetAnchorOccupant(AnchorInstance, nil)
			end
		end
	end

	WheelModel.Parent = workspace
	
	task.defer(function()
		for _, Descendant in ipairs(WheelModel:GetDescendants()) do
			if Descendant:IsA("BasePart") then
				Descendant.Anchored = false
			end
		end
		-- Restore chassis anchor state on the next frame
		if WagonRoot ~= nil and prevAnchored ~= nil then
			WagonRoot.Anchored = prevAnchored
		end
	end)
	
	return true
end

return CartAssembly