--!strict
local DragVisuals = {}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local CartAssembly = require(Modules:WaitForChild("CartAssembly"))

local Player = Players.LocalPlayer

local HIGHLIGHT_COLOR = Color3.fromRGB(182, 209, 224)
local HIGHLIGHT_FILL_TRANSPARENCY = 0.5
local HIGHLIGHT_OUTLINE_TRANSPARENCY = 0
local FADE_TIME = 0.15

local WHEEL_INDICATOR_COLOR = Color3.fromRGB(100, 200, 255)
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

	local Highlight = Instance.new("Highlight")
	Highlight.Name = "DragHighlight"
	Highlight.FillColor = HIGHLIGHT_COLOR
	Highlight.OutlineColor = HIGHLIGHT_COLOR
	Highlight.FillTransparency = HIGHLIGHT_FILL_TRANSPARENCY
	Highlight.OutlineTransparency = HIGHLIGHT_OUTLINE_TRANSPARENCY
	Highlight.Adornee = Target
	Highlight.Parent = Target
	CurrentHighlight = Highlight
end

function DragVisuals.RemoveHighlight(FadeOut: boolean): ()
	if not CurrentHighlight then
		return
	end

	if FadeOut then
		local Tween = TweenService:Create(
			CurrentHighlight,
			TweenInfo.new(FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ FillTransparency = 1, OutlineTransparency = 1 }
		)
		Tween:Play()
		Tween.Completed:Connect(function()
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

	local Beam = Instance.new("Beam")
	Beam.Name = "WheelAttachmentBeam"
	Beam.Attachment0 = WheelIndicatorAttachment0
	Beam.Attachment1 = WheelIndicatorAttachment1
	Beam.Color = ColorSequence.new(WHEEL_INDICATOR_COLOR)
	Beam.Width0 = WHEEL_INDICATOR_WIDTH
	Beam.Width1 = WHEEL_INDICATOR_WIDTH
	Beam.LightEmission = 1
	Beam.TextureSpeed = 2.5
	Beam.Texture = "rbxassetid://17377173654"
	Beam.FaceCamera = true
	Beam.Transparency = NumberSequence.new(0.3)
	Beam.Parent = WheelPart
	CurrentWheelIndicator = Beam
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

local function AnchorCF(Anchor: Instance): CFrame
	local ResultCFrame: CFrame

	if Anchor:IsA("Attachment") then
		local Parent = Anchor.Parent
		if Parent and Parent:IsA("BasePart") then
			ResultCFrame = (Parent :: BasePart).CFrame * Anchor.CFrame
		else
			ResultCFrame = CFrame.new()
		end
	elseif Anchor:IsA("BasePart") then
		ResultCFrame = (Anchor :: BasePart).CFrame
	else
		ResultCFrame = CFrame.new()
	end

	local Offset = Anchor:GetAttribute("LocalOffset")
	if typeof(Offset) == "Vector3" then
		ResultCFrame = ResultCFrame * CFrame.new(Offset)
	end

	return ResultCFrame
end

local function StripForGhost(Instance: Instance)
	if Instance:IsA("AlignPosition")
		or Instance:IsA("AlignOrientation")
		or Instance:IsA("Constraint")
		or Instance:IsA("Attachment")
		or Instance:IsA("Sound")
		or Instance:IsA("ProximityPrompt")
		or Instance:IsA("ClickDetector")
		or Instance:IsA("Motor6D")
	then
		Instance:Destroy()
		return
	end

	if Instance:IsA("SurfaceGui") or Instance:IsA("BillboardGui") then
		Instance:Destroy()
		return
	end

	if Instance:IsA("Decal") or Instance:IsA("Texture") then
		(Instance :: Decal).Transparency = GHOST_TRANSPARENCY
	end

	if Instance:IsA("BasePart") then
		local Part = Instance :: BasePart
		Part.Anchored = true
		Part.Massless = true
		Part.CanCollide = false
		Part.CanQuery = false
		Part.CanTouch = false
		Part.CastShadow = false
		Part.Material = Enum.Material.ForceField
		Part.Transparency = GHOST_TRANSPARENCY
		Part.Color = GHOST_COLOR
	end
end

local function BuildGhostTemplate(FromWheel: Model): Model
	local Template = FromWheel:Clone()
	Template.Name = "WheelGhostTemplate"

	for _, Descendant in ipairs(Template:GetDescendants()) do
		StripForGhost(Descendant)
	end

	for _, Descendant in ipairs(Template:GetDescendants()) do
		if Descendant:IsA("BasePart") then
			local Part = Descendant :: BasePart
			Part.Anchored = true
			Part.Massless = true
			Part.CanCollide = false
			Part.CanQuery = false
			Part.CanTouch = false
		end
	end

	Template.Parent = nil
	return Template
end

local function EnsurePool(FromWheel: Model)
	if not GhostTemplate then
		GhostTemplate = BuildGhostTemplate(FromWheel)
	end

	while #GhostPool < MAX_GHOSTS do
		local Ghost = GhostTemplate:Clone()
		Ghost.Name = "WheelGhost"

		for _, Descendant in ipairs(Ghost:GetDescendants()) do
			if Descendant:IsA("BasePart") then
				local Part = Descendant :: BasePart
				Part.Anchored = true
				Part.Massless = true
				Part.CanCollide = false
				Part.CanQuery = false
				Part.CanTouch = false
				Part.CastShadow = false
			end
		end

		Ghost.Parent = nil
		table.insert(GhostPool, Ghost)
	end
end

local function HideAllGhosts()
	for _, Ghost in ipairs(GhostPool) do
		if Ghost.Parent then
			Ghost.Parent = nil
		end
	end
end

local function GetOwnedCarts(): {Model}
	local Results = {}
	for _, ModelInstance in ipairs(workspace:GetDescendants()) do
		if ModelInstance:IsA("Model") and (ModelInstance:GetAttribute("Owner") == Player.UserId) then
			if ModelInstance:HasTag("Cart") or ModelInstance:GetAttribute("Type") == "Cart" then
				table.insert(Results, ModelInstance)
			end
		end
	end
	return Results
end

local function GetFreeWheelAnchors(Cart: Model): {Instance}
	local Anchors: {Instance} = {}
	local Wagon = CartAssembly.getWagon(Cart)
	if not Wagon then
		return Anchors
	end

	local Folder = Wagon:FindFirstChild("Anchors")
	if not Folder or not Folder:IsA("Folder") then
		return Anchors
	end

	for _, AnchorInstance in ipairs(Folder:GetChildren()) do
		if (AnchorInstance:IsA("Attachment") or AnchorInstance:IsA("BasePart")) and AnchorInstance.Name:match("^Wheel") then
			local OccupantUID = AnchorInstance:GetAttribute("OccupantUID")
			if not OccupantUID or OccupantUID == "" then
				table.insert(Anchors, AnchorInstance)
			end
		end
	end

	return Anchors
end

local function UpdateGhosts()
	local CurrentTime = tick()
	if CurrentTime - LastGhostUpdate < GHOST_UPDATE_INTERVAL then
		return
	end

	LastGhostUpdate = CurrentTime

	if not CurrentDraggedWheel or not CurrentDraggedWheel.Parent then
		HideAllGhosts()
		return
	end

	EnsurePool(CurrentDraggedWheel)

	local AllAnchors: {Instance} = {}
	for _, Cart in ipairs(GetOwnedCarts()) do
		local FreeAnchors = GetFreeWheelAnchors(Cart)
		for _, Anchor in ipairs(FreeAnchors) do
			table.insert(AllAnchors, Anchor)
		end
	end

	if #AllAnchors == 0 then
		HideAllGhosts()
		return
	end

	local WheelRoot = CurrentDraggedWheel.PrimaryPart or CurrentDraggedWheel:FindFirstChildWhichIsA("BasePart")
	if not WheelRoot then
		HideAllGhosts()
		return
	end

	table.sort(AllAnchors, function(AnchorA, AnchorB)
		local PositionA = AnchorCF(AnchorA).Position
		local PositionB = AnchorCF(AnchorB).Position
		return (PositionA - WheelRoot.Position).Magnitude < (PositionB - WheelRoot.Position).Magnitude
	end)

	local NeededGhosts = math.min(MAX_GHOSTS, #AllAnchors)

	for Index = 1, NeededGhosts do
		local Ghost = GhostPool[Index]
		local GhostCFrame = AnchorCF(AllAnchors[Index])

		if Ghost and GhostCFrame then
			if not Ghost.PrimaryPart then
				local AnyPart = Ghost:FindFirstChildWhichIsA("BasePart")
				if AnyPart then
					Ghost.PrimaryPart = AnyPart
				end
			end

			if Ghost.PrimaryPart then
				Ghost:PivotTo(GhostCFrame)
			end

			if Ghost.Parent ~= workspace then
				Ghost.Parent = workspace
			end
		end
	end

	for Index = NeededGhosts + 1, #GhostPool do
		local Ghost = GhostPool[Index]
		if Ghost.Parent then
			Ghost.Parent = nil
		end
	end
end

function DragVisuals.StartGhostWheels(WheelModel: Model)
	if not WheelModel or not WheelModel:IsA("Model") then
		return
	end

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

	for _, Descendant in ipairs(workspace:GetDescendants()) do
		if Descendant:IsA("Highlight") and Descendant.Name == "DragHighlight" then
			Descendant:Destroy()
		end
	end
end

return DragVisuals