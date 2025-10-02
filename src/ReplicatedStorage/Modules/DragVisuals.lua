--!strict
local DragVisuals = {}

local TweenService = game:GetService("TweenService")

-- Constants
local HIGHLIGHT_COLOR: Color3 = Color3.new(1, 1, 1)
local HIGHLIGHT_TRANSPARENCY: number = 0.75
local FADE_TIME: number = 0.3
local WHEEL_INDICATOR_COLOR = Color3.fromRGB(100, 200, 255)
local WHEEL_INDICATOR_WIDTH = 0.3

-- State
local CurrentHighlight: Highlight? = nil
local CurrentWheelIndicator: Beam? = nil
local WheelIndicatorAttachment0: Attachment? = nil
local WheelIndicatorAttachment1: Attachment? = nil

-- Create highlight on target
function DragVisuals.CreateHighlight(target: (BasePart | Model)): Highlight?
	-- Clean up existing highlights on target
	for _, child in ipairs(target:GetDescendants()) do
		if child:IsA("Highlight") and child.Name == "DragHighlight" then
			child:Destroy()
		end
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "DragHighlight"
	highlight.Adornee = target
	highlight.FillColor = HIGHLIGHT_COLOR
	highlight.FillTransparency = HIGHLIGHT_TRANSPARENCY
	highlight.OutlineColor = HIGHLIGHT_COLOR
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = target

	CurrentHighlight = highlight
	return highlight
end

-- Remove highlight with optional fade
function DragVisuals.RemoveHighlight(fadeOut: boolean?): ()
	if not CurrentHighlight then return end

	if fadeOut then
		local fadeInfo = TweenInfo.new(
			FADE_TIME,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.Out
		)

		local fadeGoal = {
			FillTransparency = 1,
			OutlineTransparency = 1
		}

		local fadeTween = TweenService:Create(CurrentHighlight, fadeInfo, fadeGoal)
		fadeTween:Play()

		fadeTween.Completed:Connect(function()
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

-- Create beam indicator for wheel attachment
function DragVisuals.CreateWheelIndicator(wheelPart: BasePart, anchorPart: BasePart): ()
	DragVisuals.RemoveWheelIndicator()

	WheelIndicatorAttachment0 = Instance.new("Attachment")
	WheelIndicatorAttachment0.Name = "WheelIndicatorStart"
	WheelIndicatorAttachment0.Parent = wheelPart

	WheelIndicatorAttachment1 = Instance.new("Attachment")
	WheelIndicatorAttachment1.Name = "WheelIndicatorEnd"
	WheelIndicatorAttachment1.Parent = anchorPart

	CurrentWheelIndicator = Instance.new("Beam")
	CurrentWheelIndicator.Name = "WheelAttachmentBeam"
	CurrentWheelIndicator.Attachment0 = WheelIndicatorAttachment0
	CurrentWheelIndicator.Attachment1 = WheelIndicatorAttachment1
	CurrentWheelIndicator.Color = ColorSequence.new(WHEEL_INDICATOR_COLOR)
	CurrentWheelIndicator.Width0 = WHEEL_INDICATOR_WIDTH
	CurrentWheelIndicator.Width1 = WHEEL_INDICATOR_WIDTH
	CurrentWheelIndicator.LightEmission = 1
	CurrentWheelIndicator.TextureSpeed = 2.5
	CurrentWheelIndicator.Texture = "rbxassetid://17377173654"
	CurrentWheelIndicator.FaceCamera = true
	CurrentWheelIndicator.Transparency = NumberSequence.new(0.3)
	CurrentWheelIndicator.Parent = wheelPart
end

-- Update wheel indicator target
function DragVisuals.UpdateWheelIndicator(newAnchor: BasePart): ()
	if WheelIndicatorAttachment1 and WheelIndicatorAttachment1.Parent ~= newAnchor then
		WheelIndicatorAttachment1.Parent = newAnchor
	end
end

-- Remove wheel indicator
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

-- Get current highlight
function DragVisuals.GetCurrentHighlight(): Highlight?
	return CurrentHighlight
end

-- Get current wheel indicator
function DragVisuals.GetCurrentWheelIndicator(): Beam?
	return CurrentWheelIndicator
end

-- Cleanup all visuals
function DragVisuals.CleanupAll(): ()
	DragVisuals.RemoveHighlight(false)
	DragVisuals.RemoveWheelIndicator()

	-- Clean up any orphaned highlights
	for _, descendant in ipairs(workspace:GetDescendants()) do
		if descendant:IsA("Highlight") and descendant.Name == "DragHighlight" then
			descendant:Destroy()
		end
	end
end

return DragVisuals