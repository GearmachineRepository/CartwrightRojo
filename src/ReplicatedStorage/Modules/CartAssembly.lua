--!strict
local CartAssembly = {}

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local UIDManager = require(script.Parent:WaitForChild("UIDManager"))
local ObjectValidator = require(script.Parent:WaitForChild("ObjectValidator"))

-- Constants
local MAX_WHEEL_SIZE_RATIO = 1.3

-- Accessors
function CartAssembly.getWagon(cart: Model): Model?
	local w = cart:FindFirstChild("Wagon")
	return (w and w:IsA("Model")) and w or nil
end

function CartAssembly.getWagonRoot(cart: Model): BasePart?
	local w = CartAssembly.getWagon(cart); if not w then return nil end
	local wr = w:FindFirstChild("WagonRoot")
	return (wr and wr:IsA("BasePart")) and wr or nil
end

-- Calculate wheel diameter from bounding box
local function GetWheelDiameter(wheelModel: Model): number
	local _, size = wheelModel:GetBoundingBox()
	-- Use largest of X or Z for circular wheels
	return math.max(size.X, size.Z)
end

-- Get all currently installed wheel diameters
local function GetInstalledWheelSizes(cart: Model): {number}
	local sizes = {}

	for _, descendant in ipairs(cart:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("PartType") == "Wheel" then
			local diameter = GetWheelDiameter(descendant)
			table.insert(sizes, diameter)
		end
	end

	return sizes
end

local function IsWheelSizeCompatible(cart: Model, newWheelDiameter: number): boolean
	local existingSizes = GetInstalledWheelSizes(cart)

	-- No wheels yet, any size is fine
	if #existingSizes == 0 then
		return true
	end

	-- Check ratio against all existing wheels
	for _, existingDiameter in ipairs(existingSizes) do
		local larger = math.max(newWheelDiameter, existingDiameter)
		local smaller = math.min(newWheelDiameter, existingDiameter)
		local ratio = larger / smaller

		if ratio > MAX_WHEEL_SIZE_RATIO then
			return false
		end
	end

	return true
end

local function getWheelsFolder(cart: Model): Instance?
	local w = CartAssembly.getWagon(cart); return w and w:FindFirstChild("Wheels") or nil
end

local function getSpinByNumber(cart: Model, axleNumber: number): BasePart?
	local wf = getWheelsFolder(cart); if not wf then return nil end
	local s = wf:FindFirstChild("Spin"..tostring(axleNumber)) or wf:FindFirstChild("Spin"..axleNumber) or wf:FindFirstChild("Spin")
	return (s and s:IsA("BasePart")) and s or nil
end

local function getMotorByNumber(cart: Model, axleNumber: number): Motor6D?
	local wr = CartAssembly.getWagonRoot(cart); if not wr then return nil end
	local m = wr:FindFirstChild("WheelMotor"..tostring(axleNumber)) or wr:FindFirstChild("WheelMotor"..axleNumber) or wr:FindFirstChild("WheelMotor")
	return (m and m:IsA("Motor6D")) and m or nil
end

-- anchor CF
local function attachmentCF(a: Attachment): CFrame
	local p = a.Parent; return (p and p:IsA("BasePart")) and (p.CFrame * a.CFrame) or CFrame.new()
end

local function anchorCF(inst: Instance): CFrame
	local cf = inst:IsA("Attachment") and attachmentCF(inst) or (inst :: BasePart).CFrame
	local off = inst:GetAttribute("LocalOffset"); if typeof(off)=="Vector3" then cf = cf * CFrame.new(off) end
	return cf
end

-- occupancy + uid
local function setAnchorOccupant(anchor: Instance, uid: string?) anchor:SetAttribute("OccupantUID", uid) end
local function getAnchorOccupant(anchor: Instance): string? return anchor:GetAttribute("OccupantUID") end

-- parse axle number
local function resolveAxleNumberFromAnchor(a: Instance): number
	local ax = a:GetAttribute("AxleNumber")
	if typeof(ax)=="number" and ax>=1 then return ax end
	local n = tostring(a.Name):match("(%d+)")
	return n and tonumber(n) or 1
end

-- nearest wheel anchor by radius; returns (anchor, axleNumber)
function CartAssembly.findNearestWheelAnchor(cart: Model, nearPos: Vector3, radius: number): (Instance?, number?)
	local w = CartAssembly.getWagon(cart); if not w then return nil, nil end
	local folder = w:FindFirstChild("Anchors"); if not folder or not folder:IsA("Folder") then return nil, nil end
	local best: Instance? = nil; local bestD = math.huge; local bestAx: number? = nil
	for _, a in ipairs(folder:GetChildren()) do
		if (a:IsA("Attachment") or a:IsA("BasePart")) and a.Name:match("^Wheel") then
			local d = (anchorCF(a).Position - nearPos).Magnitude
			if d <= radius and d < bestD then best, bestD, bestAx = a, d, resolveAxleNumberFromAnchor(a) end
		end
	end
	return best, bestAx
end

-- install: place wheel model at anchor, weld its PrimaryPart to SpinN; WheelMotorN.Part1 stays SpinN; one occupant per anchor
function CartAssembly.installWheelAttachmentAtAnchor(cart: Model, wheelModel: Model, anchor: Instance, axleNumber: number, player: Player?): boolean
	if player then
		local validation = ObjectValidator.CanAttachWheel(player, cart, wheelModel)
		if not validation.IsValid then
			warn("[CartAssembly]", validation.Reason)
			return false
		end
	end
	
	local spin = getSpinByNumber(cart, axleNumber); if not spin then return false end
	local motor = getMotorByNumber(cart, axleNumber); if not motor then return false end

	-- one occupant per anchor
	local wheelUID = UIDManager.ensureModelUID(wheelModel)
	local occ = getAnchorOccupant(anchor)
	if occ and occ ~= wheelUID then return false end

	-- ensure a root
	if not wheelModel.PrimaryPart then
		local any = wheelModel:FindFirstChildWhichIsA("BasePart"); if not any then return false end
		wheelModel.PrimaryPart = any
	end
	
	local newWheelDiameter = GetWheelDiameter(wheelModel)
	if not IsWheelSizeCompatible(cart, newWheelDiameter) then
		warn("[CartAssembly] Wheel size incompatible with existing wheels")
		return false
	end
	
	-- parent and pose
	local wf = getWheelsFolder(cart); if not wf then return false end
	wheelModel.Parent = wf
	wheelModel:PivotTo(anchorCF(anchor))

	-- weld PrimaryPart → SpinN (offset baked by placement)
	local root = wheelModel.PrimaryPart :: BasePart
	local exists: WeldConstraint? = nil
	for _, ch in ipairs(spin:GetChildren()) do
		if ch:IsA("WeldConstraint") and ((ch.Part0==spin and ch.Part1==root) or (ch.Part1==spin and ch.Part0==root)) then exists = ch; break end
	end
	if not exists then
		local w = Instance.new("WeldConstraint")
		w.Name = "WheelAttachWeld"
		w.Part0 = spin; w.Part1 = root; w.Parent = spin
	end

	-- motor target = SpinN
	if motor.Part1 ~= spin then motor.Part1 = spin end
	motor.C1 = CFrame.new()

	-- free parts
	spin.Anchored = false
	for _, d in ipairs(wheelModel:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = false end end

	-- record occupancy + metadata
	setAnchorOccupant(anchor, wheelUID)

	wheelModel:SetAttribute("AxleNumber", axleNumber)
	wheelModel:SetAttribute("AnchorName", anchor.Name)

	return true
end

-- detach: remove weld to SpinN, clear occupancy, parent to workspace
function CartAssembly.detachWheelAttachment(cart: Model, wheelModel: Model): boolean
	local ax = tonumber(wheelModel:GetAttribute("AxleNumber")) or 1
	local spin = getSpinByNumber(cart, ax); if not spin then return false end
	local root = (wheelModel.PrimaryPart or wheelModel:FindFirstChildWhichIsA("BasePart")) :: BasePart?; if not root then return false end

	-- remove weld to SpinN
	local weld: WeldConstraint? = nil
	for _, ch in ipairs(spin:GetChildren()) do
		if ch:IsA("WeldConstraint") and ((ch.Part0==spin and ch.Part1==root) or (ch.Part1==spin and ch.Part0==root)) then weld = ch; break end
	end
	if not weld then return false end
	weld:Destroy()

	-- clear occupancy on the specific anchor
	local wagon = CartAssembly.getWagon(cart)
	if wagon then
		local anchors = wagon:FindFirstChild("Anchors")
		if anchors then
			local an = wheelModel:GetAttribute("AnchorName")
			local a = an and anchors:FindFirstChild(tostring(an))
			if a then setAnchorOccupant(a, nil) end
		end
	end

	-- free the wheel into world
	wheelModel.Parent = workspace
	for _, d in ipairs(wheelModel:GetDescendants()) do if d:IsA("BasePart") then d.Anchored = false end end
	return true
end

return CartAssembly