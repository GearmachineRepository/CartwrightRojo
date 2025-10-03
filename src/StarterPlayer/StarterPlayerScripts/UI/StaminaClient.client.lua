--!strict
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer

local MAX_STAMINA = 100
local STAMINA_BAR_HEIGHT = 0.9

local CurrentStamina = MAX_STAMINA
local IsVisible = false
local FadeTween: Tween?

local StaminaBarGui: ScreenGui
local StaminaFrame: Frame
local StaminaBar: Frame

-- Create GUI
local function CreateStaminaBar()
	StaminaBarGui = Instance.new("ScreenGui")
	StaminaBarGui.Name = "StaminaBarGui"
	StaminaBarGui.ResetOnSpawn = false
	StaminaBarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	StaminaFrame = Instance.new("Frame")
	StaminaFrame.Name = "StaminaFrame"
	StaminaFrame.AnchorPoint = Vector2.new(0.5, 1)
	StaminaFrame.Position = UDim2.fromScale(0.5, STAMINA_BAR_HEIGHT)
	StaminaFrame.Size = UDim2.fromOffset(200, 20)
	StaminaFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	StaminaFrame.BorderSizePixel = 2
	StaminaFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	StaminaFrame.BackgroundTransparency = 1
	StaminaFrame.Parent = StaminaBarGui

	local UICorner = Instance.new("UICorner")
	UICorner.CornerRadius = UDim.new(0, 4)
	UICorner.Parent = StaminaFrame

	StaminaBar = Instance.new("Frame")
	StaminaBar.Name = "StaminaBar"
	StaminaBar.Size = UDim2.new(1, -4, 1, -4)
	StaminaBar.Position = UDim2.fromOffset(2, 2)
	StaminaBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	StaminaBar.BorderSizePixel = 0
	StaminaBar.BackgroundTransparency = 1
	StaminaBar.Parent = StaminaFrame

	local BarCorner = Instance.new("UICorner")
	BarCorner.CornerRadius = UDim.new(0, 3)
	BarCorner.Parent = StaminaBar

	StaminaBarGui.Parent = Player:WaitForChild("PlayerGui")
end

-- Fade GUI in/out
local function FadeStaminaBar(visible: boolean)
	if IsVisible == visible then return end
	IsVisible = visible

	if FadeTween then
		FadeTween:Cancel()
	end

	local targetTransparency = visible and 0 or 1

	FadeTween = TweenService:Create(StaminaFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = targetTransparency
	})
	FadeTween:Play()

	TweenService:Create(StaminaBar, TweenInfo.new(0.5), {
		BackgroundTransparency = targetTransparency
	}):Play()
end

-- Update bar visuals
local function UpdateStaminaBar()
	if not StaminaBar then return end

	local staminaPercent = math.clamp(CurrentStamina / MAX_STAMINA, 0, 1)
	local barWidth = math.max(0, (StaminaFrame.AbsoluteSize.X - 4) * staminaPercent)
	StaminaBar.Size = UDim2.new(0, barWidth, 1, -4)

	if staminaPercent > 0.5 then
		StaminaBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	elseif staminaPercent > 0.25 then
		StaminaBar.BackgroundColor3 = Color3.fromRGB(182, 182, 143)
	else
		StaminaBar.BackgroundColor3 = Color3.fromRGB(165, 119, 119)
	end

	FadeStaminaBar(CurrentStamina < MAX_STAMINA)
end

-- Watch for server-side Stamina changes
local function OnStaminaChanged()
	local newValue = Player:GetAttribute("Stamina")
	if typeof(newValue) == "number" then
		CurrentStamina = newValue
		UpdateStaminaBar()
	end
end

-- Watch for sprinting attribute
local function OnSprintingChanged()
	local isSprinting = Player:GetAttribute("Sprinting")
    -- You could add visual feedback for sprinting state here if desired
end

CreateStaminaBar()

Player:GetAttributeChangedSignal("Stamina"):Connect(OnStaminaChanged)
Player:GetAttributeChangedSignal("Sprinting"):Connect(OnSprintingChanged)

Player.CharacterAdded:Connect(function()
	task.wait(1) 
	OnStaminaChanged()
	OnSprintingChanged()
end)

OnStaminaChanged()
OnSprintingChanged()
