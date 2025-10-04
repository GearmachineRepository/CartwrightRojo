--!strict
local DragVisuals = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CartAssembly = require(Modules:WaitForChild("CartAssembly"))

local Player = Players.LocalPlayer

local HIGHLIGHT_COLOR = Color3.fromRGB(100, 200, 255)
local HIGHLIGHT_FILL_TRANSPARENCY = 0.5
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0
local FADE_TIME = 0.15

local WHEEL_INDICATOR_COLOR = Color3.fromRGB(255, 200, 100)
local WHEEL_INDICATOR_WIDTH = 0.5

local GHOST_TRANSPARENCY = 0.25
local GHOST_COLOR = Color3.fromRGB(100, 200, 255)

local MAX_GHOSTS = 8
local GHOST_UPDATE_INTERVAL = 0.12

local CurrentHighlight: Highlight? = nil
local CurrentWheelIndicator: Beam? = nil
local WheelIndicatorAttachment0: Attachment? = nil
local WheelIndicatorAttachment1: Attachment? = nil

local CurrentDraggedWheel: Model? = nil
local LastGhostUpdate = 0

local GhostTemplate: Model? = nil
local GhostPool: {Model} = {}
local GhostUpdateConnection: RBXScriptConnection? = nil

function DragVisuals.CreateHighlight(Target: Instance): ()
	DragVisuals.RemoveHighlight(false)
	local hl = Instance.new("Highlight")
	hl.Name = "DragHighlight"
	hl.FillColor = HIGHLIGHT_COLOR
	hl.OutlineColor = HIGHLIGHT_COLOR
	hl.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
	hl.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
	hl.Adornee = Target
	hl.Parent = Target
	CurrentHighlight = hl
end

function DragVisuals.RemoveHighlight(FadeOut: boolean): ()
	if not CurrentHighlight then return end
	if FadeOut then
		local t = TweenService:Create(
			CurrentHighlight,
			TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FillTransparency = 1, OutlineTransparency = 1 }
		)
		t:Play()
		t.Completed:Connect(function()
			if CurrentHighlight then
				CurrentHighlight:Destroy()
				CurrentHighlight = nil
			end
		end)
	else
		CurrentHighlight:Destroy()
		CurrentHighlight = nil
	end
end

function DragVisuals.CreateWheelIndicator(WheelPart: BasePart, AnchorPart: BasePart): ()
	DragVisuals.RemoveWheelIndicator()
	WheelIndicatorAttachment0 = Instance.new("Attachment")
	WheelIndicatorAttachment0.Name = "WheelIndicatorStart"
	WheelIndicatorAttachment0.Parent = WheelPart
	WheelIndicatorAttachment1 = Instance.new("Attachment")
	WheelIndicatorAttachment1.Name = "WheelIndicatorEnd"
	WheelIndicatorAttachment1.Parent = AnchorPart
	local beam = Instance.new("Beam")
	beam.Name = "WheelAttachmentBeam"
	beam.Attachment0 = WheelIndicatorAttachment0
	beam.Attachment1 = WheelIndicatorAttachment1
	beam.Color = ColorSequence.new(WHEEL_INDICATOR_COLOR)
	beam.Width0 = WHEEL_INDICATOR_WIDTH
	beam.Width1 = WHEEL_INDICATOR_WIDTH
	beam.LightEmission = 1
	beam.TextureSpeed = 2.5
	beam.Texture = "rbxassetid://17377173654"
	beam.FaceCamera = true
	beam.Transparency = NumberSequence.new(0.3)
	beam.Parent = WheelPart
	CurrentWheelIndicator = beam
end

function DragVisuals.UpdateWheelIndicator(NewAnchor: BasePart): ()
	if WheelIndicatorAttachment1 and WheelIndicatorAttachment1.Parent ~= NewAnchor then
		WheelIndicatorAttachment1.Parent = NewAnchor
	end
end

function DragVisuals.RemoveWheelIndicator(): ()
	if CurrentWheelIndicator then
		CurrentWheelIndicator:Destroy()
		CurrentWheelIndicator = nil
	end
	if WheelIndicatorAttachment0 then
		WheelIndicatorAttachment0:Destroy()
		WheelIndicatorAttachment0 = nil
	end
	if WheelIndicatorAttachment1 then
		WheelIndicatorAttachment1:Destroy()
		WheelIndicatorAttachment1 = nil
	end
end

local function AnchorCF(anchor: Instance): CFrame
	local cf: CFrame
	if anchor:IsA("Attachment") then
		local parent = anchor.Parent
		if parent and parent:IsA("BasePart") then
			cf = (parent :: BasePart).CFrame * anchor.CFrame
		else
			cf = CFrame.new()
		end
	elseif anchor:IsA("BasePart") then
		cf = (anchor :: BasePart).CFrame
	else
		cf = CFrame.new()
	end
	local offset = anchor:GetAttribute("LocalOffset")
	if typeof(offset) == "Vector3" then
		cf = cf * CFrame.new(offset)
	end
	return cf
end

local function StripForGhost(inst: Instance)
	if inst:IsA("AlignPosition")
		or inst:IsA("AlignOrientation")
		or inst:IsA("Constraint")
		or inst:IsA("Attachment")
		or inst:IsA("Sound")
		or inst:IsA("ProximityPrompt")
		or inst:IsA("ClickDetector")
		or inst:IsA("Motor6D")
	then
		inst:Destroy()
		return
	end
	if inst:IsA("SurfaceGui") or inst:IsA("BillboardGui") then
		inst:Destroy()
		return
	end
	if inst:IsA("Decal") or inst:IsA("Texture") then
		(inst :: Decal).Transparency = GHOST_TRANSPARENCY
	end
	if inst:IsA("BasePart") then
		local p = inst :: BasePart
		p.Anchored = true
		p.Massless = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Material = Enum.Material.ForceField
		p.Transparency = GHOST_TRANSPARENCY
		p.Color = GHOST_COLOR
	end
end

local function BuildGhostTemplate(fromWheel: Model): Model
	local template = fromWheel:Clone()
	template.Name = "WheelGhostTemplate"
	for _, d in ipairs(template:GetDescendants()) do
		StripForGhost(d)
	end
	for _, d in ipairs(template:GetDescendants()) do
		if d:IsA("BasePart") then
			local p = d :: BasePart
			p.Anchored = true
			p.Massless = true
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
		end
	end
	template.Parent = nil
	return template
end

local function EnsurePool(fromWheel: Model)
	if not GhostTemplate then
		GhostTemplate = BuildGhostTemplate(fromWheel)
	end
	while #GhostPool < MAX_GHOSTS do
		local g = GhostTemplate:Clone()
		g.Name = "WheelGhost"
		for _, d in ipairs(g:GetDescendants()) do
			if d:IsA("BasePart") then
				local p = d :: BasePart
				p.Anchored = true
				p.Massless = true
				p.CanCollide = false
				p.CanQuery = false
				p.CanTouch = false
				p.CastShadow = false
			end
		end
		g.Parent = nil
		table.insert(GhostPool, g)
	end
end

local function HideAllGhosts()
	for _, g in ipairs(GhostPool) do
		if g.Parent then g.Parent = nil end
	end
end

local function GetOwnedCarts(): {Model}
	local results = {}
	for _, m in ipairs(workspace:GetDescendants()) do
		if m:IsA("Model") and (m:GetAttribute("Owner") == Player.UserId) then
			if m:HasTag("Cart") or m:GetAttribute("Type") == "Cart" then
				table.insert(results, m)
			end
		end
	end
	return results
end

local function GetFreeWheelAnchors(cart: Model): {Instance}
	local anchors: {Instance} = {}
	local wagon = CartAssembly.getWagon(cart)
	if not wagon then return anchors end
	local folder = wagon:FindFirstChild("Anchors")
	if not folder or not folder:IsA("Folder") then return anchors end
	for _, a in ipairs(folder:GetChildren()) do
		if (a:IsA("Attachment") or a:IsA("BasePart")) and a.Name:match("^Wheel") then
			local occ = a:GetAttribute("OccupantUID")
			if not occ or occ == "" then
				table.insert(anchors, a)
			end
		end
	end
	return anchors
end

local function UpdateGhosts()
	local t = tick()
	if t - LastGhostUpdate < GHOST_UPDATE_INTERVAL then return end
	LastGhostUpdate = t
	if not CurrentDraggedWheel or not CurrentDraggedWheel.Parent then
		HideAllGhosts()
		return
	end
	EnsurePool(CurrentDraggedWheel)
	local anchors: {Instance} = {}
	for _, cart in ipairs(GetOwnedCarts()) do
		local free = GetFreeWheelAnchors(cart)
		for _, a in ipairs(free) do table.insert(anchors, a) end
	end
	if #anchors == 0 then
		HideAllGhosts()
		return
	end
	local wheelRoot = CurrentDraggedWheel.PrimaryPart or CurrentDraggedWheel:FindFirstChildWhichIsA("BasePart")
	if not wheelRoot then
		HideAllGhosts()
		return
	end
	table.sort(anchors, function(a, b)
		local pa = AnchorCF(a).Position
		local pb = AnchorCF(b).Position
		return (pa - wheelRoot.Position).Magnitude < (pb - wheelRoot.Position).Magnitude
	end)
	local needed = math.min(MAX_GHOSTS, #anchors)
	for i = 1, needed do
		local g = GhostPool[i]
		local cf = AnchorCF(anchors[i])
		if g and cf then
			if not g.PrimaryPart then
				local any = g:FindFirstChildWhichIsA("BasePart")
				if any then g.PrimaryPart = any end
			end
			if g.PrimaryPart then
				g:PivotTo(cf)
			end
			if g.Parent ~= workspace then
				g.Parent = workspace
			end
		end
	end
	for i = needed + 1, #GhostPool do
		local g = GhostPool[i]
		if g.Parent then g.Parent = nil end
	end
end

function DragVisuals.StartGhostWheels(WheelModel: Model)
	if not WheelModel or not WheelModel:IsA("Model") then return end
	CurrentDraggedWheel = WheelModel
	LastGhostUpdate = 0
	EnsurePool(WheelModel)
	HideAllGhosts()
	if GhostUpdateConnection then
		GhostUpdateConnection:Disconnect()
	end
	GhostUpdateConnection = RunService.Heartbeat:Connect(UpdateGhosts)
end

function DragVisuals.StopGhostWheels()
	HideAllGhosts()
	CurrentDraggedWheel = nil
	if GhostUpdateConnection then
		GhostUpdateConnection:Disconnect()
		GhostUpdateConnection = nil
	end
end

function DragVisuals.GetCurrentHighlight(): Highlight?
	return CurrentHighlight
end

function DragVisuals.GetCurrentWheelIndicator(): Beam?
	return CurrentWheelIndicator
end

function DragVisuals.CleanupAll(): ()
	DragVisuals.RemoveHighlight(false)
	DragVisuals.RemoveWheelIndicator()
	DragVisuals.StopGhostWheels()
	for _, d in ipairs(workspace:GetDescendants()) do
		if d:IsA("Highlight") and d.Name == "DragHighlight" then
			d:Destroy()
		end
	end
end

return DragVisuals