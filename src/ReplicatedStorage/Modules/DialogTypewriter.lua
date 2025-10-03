--!strict
local DialogTypewriter = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local DialogSoundsFolder = ReplicatedStorage:FindFirstChild("DialogLetters")

local MAX_MESSAGES = 3
local ROW_HEIGHT = 28
local HOLD_TIME = 3.0
local TYPE_SPEED_DEFAULT = 0.05
local MAX_DISTANCE = 75
local YELLING_THRESHOLD = 0.7
local FADE_TI = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
local FADE_OUT_GOAL = {TextTransparency = 1, TextStrokeTransparency = 1}

local Equalizer = Instance.new("EqualizerSoundEffect")
Equalizer.HighGain = -24
Equalizer.LowGain = -5
Equalizer.MidGain = -10
Equalizer.Enabled = true
Equalizer.Parent = script

local PitchShift = Instance.new("PitchShiftSoundEffect")
PitchShift.Octave = 0.65
PitchShift.Enabled = true
PitchShift.Parent = script

local Effects: {[number]: Instance} = {
	[1] = PitchShift,
	[2] = Equalizer
}

local function GetLetterSound(Letter: string): Sound?
	if not DialogSoundsFolder then return nil end
	local Child = DialogSoundsFolder:FindFirstChild(Letter:upper())
	if Child and Child:IsA("Sound") then
		return Child:Clone()
	end
	return nil
end

local function IsYelling(Message: string): boolean
	local UpperCount = 0
	local LetterCount = 0
	
	for CharIndex = 1, #Message do
		local Char = Message:sub(CharIndex, CharIndex)
		if Char:match("%a") then
			LetterCount += 1
			if Char:match("%u") then
				UpperCount += 1
			end
		end
	end
	
	if LetterCount == 0 then return false end
	
	local UpperRatio = UpperCount / LetterCount
	return UpperRatio >= YELLING_THRESHOLD
end

local function GetOrCreateBubble(Head: BasePart)
	local Bubble = Head:FindFirstChild("DialogBubble") :: BillboardGui?
	local Container: Frame? = nil
	local Layout: UIListLayout? = nil

	if Bubble and Bubble:IsA("BillboardGui") then
		Container = Bubble:FindFirstChild("Container") :: Frame?
		Layout = Container and Container:FindFirstChildOfClass("UIListLayout")
		if Container and Layout then
			return Bubble, Container, Layout
		end
	end

	Bubble = Instance.new("BillboardGui")
	Bubble.Name = "DialogBubble"
	Bubble.Size = UDim2.fromOffset(260, (ROW_HEIGHT * MAX_MESSAGES) + 16)
	Bubble.StudsOffset = Vector3.new(0, 5, 0)
	Bubble.MaxDistance = MAX_DISTANCE
	Bubble.AlwaysOnTop = true
	Bubble.Parent = Head
	Bubble:SetAttribute("MessageCount", 0)

	Container = Instance.new("Frame")
	Container.Name = "Container"
	Container.Size = UDim2.fromScale(1, 1)
	Container.BackgroundTransparency = 1
	Container.BorderSizePixel = 0
	Container.ClipsDescendants = false
	Container.Parent = Bubble

	local Pad = Instance.new("UIPadding")
	Pad.PaddingLeft = UDim.new(0, 8)
	Pad.PaddingRight = UDim.new(0, 8)
	Pad.PaddingTop = UDim.new(0, 4)
	Pad.PaddingBottom = UDim.new(0, 4)
	Pad.Parent = Container

	Layout = Instance.new("UIListLayout")
	Layout.FillDirection = Enum.FillDirection.Vertical
	Layout.SortOrder = Enum.SortOrder.LayoutOrder
	Layout.Padding = UDim.new(0, 4)
	Layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	Layout.Parent = Container

	return Bubble, Container, Layout
end

local function CreateMessage(Container: Frame, Bubble: BillboardGui, IsYellingMessage: boolean): TextLabel
	local MessageCount = (Bubble:GetAttribute("MessageCount") :: number) or 0
	MessageCount += 1
	Bubble:SetAttribute("MessageCount", MessageCount)

	local Label = Instance.new("TextLabel")
	Label.Name = "Message"
	Label.LayoutOrder = MessageCount
	Label.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	Label.BackgroundTransparency = 1
	Label.TextColor3 = Color3.new(1, 1, 1)
	Label.TextStrokeTransparency = 0.5
	Label.TextScaled = true
	Label.Font = Enum.Font.Gotham
	Label.Text = ""
	Label.Parent = Container
	
	if IsYellingMessage then
		Label.Font = Enum.Font.GothamBold
		Label.TextColor3 = Color3.fromRGB(255, 100, 100)
		Label.TextStrokeTransparency = 0.3
	end

	return Label
end

local function RemoveOldestMessage(Container: Frame)
	local Messages = {}
	for _, Child in ipairs(Container:GetChildren()) do
		if Child:IsA("TextLabel") and Child.Name == "Message" then
			table.insert(Messages, Child)
		end
	end
	
	if #Messages <= MAX_MESSAGES then return end
	
	table.sort(Messages, function(A, B) 
		return A.LayoutOrder < B.LayoutOrder 
	end)
	
	Messages[1]:Destroy()
end

function DialogTypewriter:PlayDialog(Character: Model, Message: string, TypingSpeed: number?)
	TypingSpeed = TypingSpeed or TYPE_SPEED_DEFAULT
	if type(Message) ~= "string" or #Message == 0 then return end

	local Head = Character:FindFirstChild("Head")
	if not Head or not Head:IsA("BasePart") then return end

	local Bubble, Container = GetOrCreateBubble(Head)
	
	RemoveOldestMessage(Container)
	
	local IsYellingMessage = IsYelling(Message)
	local Label = CreateMessage(Container, Bubble, IsYellingMessage)
	
	local TypeSpeed = TypingSpeed
	if IsYellingMessage then
		TypeSpeed = TypingSpeed * 0.7
	end

	for I = 1, #Message do
		Label.Text = Message:sub(1, I)

		local S = GetLetterSound(Message:sub(I, I))
		if S then
			S.Parent = Head
			
			if IsYellingMessage then
				S.Volume = S.Volume * 1.5
				S.PlaybackSpeed = S.PlaybackSpeed * 1.2
			end
			
			if #Effects > 0 then
				for _, Effect in ipairs(Effects) do
					if Effect:IsA("Instance") then 
						Effect:Clone().Parent = S 
					end
				end
			end
			S:Play()
			Debris:AddItem(S, 2)
		end

		task.wait(TypeSpeed)
		if not Head.Parent then return end
	end

	task.delay(HOLD_TIME, function()
		if Label and Label.Parent then
			local Tween = TweenService:Create(Label, FADE_TI, FADE_OUT_GOAL)
			Tween:Play()
			Tween.Completed:Wait()
			if Label and Label.Parent then
				Label:Destroy()
			end
		end
	end)
end

return DialogTypewriter