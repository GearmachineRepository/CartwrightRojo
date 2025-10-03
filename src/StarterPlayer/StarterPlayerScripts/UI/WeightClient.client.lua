--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))
local CartConfigurations = require(Modules:WaitForChild("CartConfigurations"))

local Player = Players.LocalPlayer

local MAX_PLAYER_WEIGHT = 50
local WEIGHT_BAR_HEIGHT = 0.825
local BAR_SPACING = 28

local CurrentPlayerWeight = 0
local CurrentCartWeight = 0
local CurrentCartMaxWeight = 0
local IsVisible = false
local FadeTween: Tween?

local WeightBarGui: ScreenGui
local ContainerFrame: Frame
local PlayerWeightFrame: Frame
local PlayerWeightBar: Frame
local PlayerWeightLabel: TextLabel
local CartWeightFrame: Frame
local CartWeightBar: Frame
local CartWeightLabel: TextLabel

local function GetColorForWeight(CurrentWeight: number, MaxWeight: number): Color3
	local Percent = CurrentWeight / MaxWeight
	
	if Percent <= 0.6 then
		return Color3.fromRGB(100, 200, 100)
	elseif Percent <= 0.85 then
		return Color3.fromRGB(200, 200, 100)
	elseif Percent <= 1.0 then
		return Color3.fromRGB(200, 150, 100)
	else
		return Color3.fromRGB(200, 100, 100)
	end
end

local function GetWheelWeight(WheelName: string): number
	local Config = ObjectDatabase.GetObjectConfig(WheelName)
	if Config and Config.Weight then
		return Config.Weight
	end
	return 0
end

local function GetWheelLoadCapacity(WheelName: string): number
	local Config = ObjectDatabase.GetObjectConfig(WheelName)
	if Config and Config.LoadCapacity then
		return Config.LoadCapacity
	end
	return 10
end

local function CalculateCartMaxWeight(Cart: Model): number
	local CartConfig = CartConfigurations.GetConfig(Cart)
	local BaseMaxWeight = CartConfig.BaseMaxWeight or 80
	
	local TotalLoadCapacity = 0
	
	for _, Descendant in ipairs(Cart:GetDescendants()) do
		if Descendant:IsA("Model") and Descendant:GetAttribute("PartType") == "Wheel" then
			TotalLoadCapacity += GetWheelLoadCapacity(Descendant.Name)
		end
	end
	
	return BaseMaxWeight + TotalLoadCapacity
end

local function GetCartWeight(Cart: Model): number
	local TotalWeight = 0
	
	local Wagon = Cart:FindFirstChild("Wagon")
	if not Wagon then return 0 end
	
	local PlacementGrid = Wagon:FindFirstChild("PlacementGrid", true)
	if PlacementGrid then
		for _, Item in ipairs(PlacementGrid:GetDescendants()) do
			if Item:IsA("Model") and Item:GetAttribute("SnappedToGrid") then
				local ItemConfig = ObjectDatabase.GetObjectConfig(Item.Name)
				if ItemConfig and ItemConfig.Weight then
					TotalWeight += ItemConfig.Weight
				end
			end
		end
	end
	
	for _, Descendant in ipairs(Cart:GetDescendants()) do
		if Descendant:IsA("Model") and Descendant:GetAttribute("PartType") == "Wheel" then
			TotalWeight += GetWheelWeight(Descendant.Name)
		end
	end
	
	return TotalWeight
end

local function CreateWeightBar()
	WeightBarGui = Instance.new("ScreenGui")
	WeightBarGui.Name = "WeightBarGui"
	WeightBarGui.ResetOnSpawn = false
	WeightBarGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	ContainerFrame = Instance.new("Frame")
	ContainerFrame.Name = "ContainerFrame"
	ContainerFrame.AnchorPoint = Vector2.new(0.5, 1)
	ContainerFrame.Position = UDim2.fromScale(0.5, WEIGHT_BAR_HEIGHT)
	ContainerFrame.Size = UDim2.fromOffset(200, 20)
	ContainerFrame.BackgroundTransparency = 1
	ContainerFrame.Parent = WeightBarGui

	PlayerWeightFrame = Instance.new("Frame")
	PlayerWeightFrame.Name = "PlayerWeightFrame"
	PlayerWeightFrame.AnchorPoint = Vector2.new(0, 0)
	PlayerWeightFrame.Position = UDim2.fromOffset(0, 0)
	PlayerWeightFrame.Size = UDim2.fromOffset(200, 20)
	PlayerWeightFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	PlayerWeightFrame.BorderSizePixel = 2
	PlayerWeightFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	PlayerWeightFrame.BackgroundTransparency = 1
	PlayerWeightFrame.Parent = ContainerFrame

	local PlayerCorner = Instance.new("UICorner")
	PlayerCorner.CornerRadius = UDim.new(0, 4)
	PlayerCorner.Parent = PlayerWeightFrame

	PlayerWeightBar = Instance.new("Frame")
	PlayerWeightBar.Name = "PlayerWeightBar"
	PlayerWeightBar.Size = UDim2.new(1, -4, 1, -4)
	PlayerWeightBar.Position = UDim2.fromOffset(2, 2)
	PlayerWeightBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	PlayerWeightBar.BorderSizePixel = 0
	PlayerWeightBar.BackgroundTransparency = 1
	PlayerWeightBar.Parent = PlayerWeightFrame

	local PlayerBarCorner = Instance.new("UICorner")
	PlayerBarCorner.CornerRadius = UDim.new(0, 3)
	PlayerBarCorner.Parent = PlayerWeightBar

	PlayerWeightLabel = Instance.new("TextLabel")
	PlayerWeightLabel.Name = "PlayerWeightLabel"
	PlayerWeightLabel.Size = UDim2.fromScale(1, 1)
	PlayerWeightLabel.BackgroundTransparency = 1
	PlayerWeightLabel.Text = "0/50"
	PlayerWeightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayerWeightLabel.TextSize = 12
	PlayerWeightLabel.Font = Enum.Font.GothamBold
	PlayerWeightLabel.TextStrokeTransparency = 0.5
	PlayerWeightLabel.TextTransparency = 1
	PlayerWeightLabel.Parent = PlayerWeightFrame

	CartWeightFrame = Instance.new("Frame")
	CartWeightFrame.Name = "CartWeightFrame"
	CartWeightFrame.AnchorPoint = Vector2.new(0, 0)
	CartWeightFrame.Position = UDim2.fromOffset(0, BAR_SPACING)
	CartWeightFrame.Size = UDim2.fromOffset(200, 20)
	CartWeightFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	CartWeightFrame.BorderSizePixel = 2
	CartWeightFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
	CartWeightFrame.BackgroundTransparency = 1
	CartWeightFrame.Visible = false
	CartWeightFrame.Parent = ContainerFrame

	local CartCorner = Instance.new("UICorner")
	CartCorner.CornerRadius = UDim.new(0, 4)
	CartCorner.Parent = CartWeightFrame

	CartWeightBar = Instance.new("Frame")
	CartWeightBar.Name = "CartWeightBar"
	CartWeightBar.Size = UDim2.new(1, -4, 1, -4)
	CartWeightBar.Position = UDim2.fromOffset(2, 2)
	CartWeightBar.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	CartWeightBar.BorderSizePixel = 0
	CartWeightBar.BackgroundTransparency = 1
	CartWeightBar.Parent = CartWeightFrame

	local CartBarCorner = Instance.new("UICorner")
	CartBarCorner.CornerRadius = UDim.new(0, 3)
	CartBarCorner.Parent = CartWeightBar

	CartWeightLabel = Instance.new("TextLabel")
	CartWeightLabel.Name = "CartWeightLabel"
	CartWeightLabel.Size = UDim2.fromScale(1, 1)
	CartWeightLabel.BackgroundTransparency = 1
	CartWeightLabel.Text = "0/100"
	CartWeightLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	CartWeightLabel.TextSize = 12
	CartWeightLabel.Font = Enum.Font.GothamBold
	CartWeightLabel.TextStrokeTransparency = 0.5
	CartWeightLabel.TextTransparency = 1
	CartWeightLabel.Parent = CartWeightFrame

	WeightBarGui.Parent = Player:WaitForChild("PlayerGui")
end

local function FadeWeightBar(Visible: boolean)
	if IsVisible == Visible then return end
	IsVisible = Visible

	if FadeTween then
		FadeTween:Cancel()
	end

	local TargetTransparency = Visible and 0 or 1

	FadeTween = TweenService:Create(PlayerWeightFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		BackgroundTransparency = TargetTransparency
	})
	FadeTween:Play()

	TweenService:Create(PlayerWeightBar, TweenInfo.new(0.5), {
		BackgroundTransparency = TargetTransparency
	}):Play()

	TweenService:Create(PlayerWeightLabel, TweenInfo.new(0.5), {
		TextTransparency = TargetTransparency,
		TextStrokeTransparency = Visible and 0.5 or 1
	}):Play()

	if CartWeightFrame.Visible then
		TweenService:Create(CartWeightFrame, TweenInfo.new(0.5), {
			BackgroundTransparency = TargetTransparency
		}):Play()

		TweenService:Create(CartWeightBar, TweenInfo.new(0.5), {
			BackgroundTransparency = TargetTransparency
		}):Play()

		TweenService:Create(CartWeightLabel, TweenInfo.new(0.5), {
			TextTransparency = TargetTransparency,
			TextStrokeTransparency = Visible and 0.5 or 1
		}):Play()
	end
end

local function UpdatePlayerWeightBar()
	if not PlayerWeightBar then return end

	local WeightPercent = math.clamp(CurrentPlayerWeight / MAX_PLAYER_WEIGHT, 0, 1)
	local BarWidth = math.max(0, (PlayerWeightFrame.AbsoluteSize.X - 4) * WeightPercent)
	PlayerWeightBar.Size = UDim2.new(0, BarWidth, 1, -4)

	PlayerWeightBar.BackgroundColor3 = GetColorForWeight(CurrentPlayerWeight, MAX_PLAYER_WEIGHT)
	PlayerWeightLabel.Text = string.format("%d/%d", math.floor(CurrentPlayerWeight), MAX_PLAYER_WEIGHT)

	FadeWeightBar(CurrentPlayerWeight > 0 or CurrentCartWeight > 0)
end

local function UpdateCartWeightBar()
	if not CartWeightBar then return end

	if CurrentCartMaxWeight > 0 then
		local WeightPercent = math.clamp(CurrentCartWeight / CurrentCartMaxWeight, 0, 1)
		local BarWidth = math.max(0, (CartWeightFrame.AbsoluteSize.X - 4) * WeightPercent)
		CartWeightBar.Size = UDim2.new(0, BarWidth, 1, -4)

		CartWeightBar.BackgroundColor3 = GetColorForWeight(CurrentCartWeight, CurrentCartMaxWeight)
		CartWeightLabel.Text = string.format("%d/%d", math.floor(CurrentCartWeight), math.floor(CurrentCartMaxWeight))
	end
end

local function FindPlayerCart(): Model?
	for _, Object in ipairs(workspace:GetDescendants()) do
		if Object:IsA("Model") and Object:GetAttribute("Type") == "Cart" then
			if Object:GetAttribute("Owner") == Player.UserId and Object:GetAttribute("AttachedTo") == Player.Name then
				return Object
			end
		end
	end
	return nil
end

local function CalculatePlayerWeight(): number
	local TotalWeight = 0
	
	local Backpack = Player:FindFirstChild("Backpack")
	if Backpack then
		for _, Item in ipairs(Backpack:GetChildren()) do
			if Item:IsA("Tool") then
				local Config = ObjectDatabase.GetObjectConfig(Item.Name)
				if Config and Config.Weight then
					TotalWeight += Config.Weight
				end
			end
		end
	end
	
	local Character = Player.Character
	if Character then
		for _, Item in ipairs(Character:GetChildren()) do
			if Item:IsA("Tool") then
				local Config = ObjectDatabase.GetObjectConfig(Item.Name)
				if Config and Config.Weight then
					TotalWeight += Config.Weight
				end
			end
		end
	end
	
	return TotalWeight
end

local function UpdateWeights()
	CurrentPlayerWeight = CalculatePlayerWeight()

	local IsCarting = Player:GetAttribute("Carting")
	if IsCarting then
		local Cart = FindPlayerCart()
		if Cart then
			CurrentCartWeight = GetCartWeight(Cart)
			CurrentCartMaxWeight = CalculateCartMaxWeight(Cart)
			CartWeightFrame.Visible = true
		else
			CurrentCartWeight = 0
			CurrentCartMaxWeight = 0
			CartWeightFrame.Visible = false
		end
	else
		CurrentCartWeight = 0
		CurrentCartMaxWeight = 0
		CartWeightFrame.Visible = false
	end

	UpdatePlayerWeightBar()
	UpdateCartWeightBar()
end

local function OnCartingChanged()
	UpdateWeights()
end

CreateWeightBar()

local function SetupBackpackMonitoring()
	local Backpack = Player:WaitForChild("Backpack", 5)
	if Backpack then
		Backpack.ChildAdded:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.05)
				UpdateWeights()
			end
		end)
		
		Backpack.ChildRemoved:Connect(function(Child)
			if Child:IsA("Tool") then
				task.wait(0.05)
				UpdateWeights()
			end
		end)
	end
end

local function SetupCharacterMonitoring(Character: Model)
	Character.ChildAdded:Connect(function(Child)
		if Child:IsA("Tool") then
			task.wait(0.05)
			UpdateWeights()
		end
	end)
	
	Character.ChildRemoved:Connect(function(Child)
		if Child:IsA("Tool") then
			task.wait(0.05)
			UpdateWeights()
		end
	end)
end

SetupBackpackMonitoring()

Player:GetAttributeChangedSignal("Carting"):Connect(OnCartingChanged)

Player.CharacterAdded:Connect(function(Character)
	task.wait(0.5)
	SetupCharacterMonitoring(Character)
	UpdateWeights()
end)

if Player.Character then
	SetupCharacterMonitoring(Player.Character)
end

task.spawn(function()
	while task.wait(0.5) do
		UpdateWeights()
	end
end)

UpdateWeights()