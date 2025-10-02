--!strict
local DialogTypewriter = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local DialogSoundsFolder = ReplicatedStorage:FindFirstChild("DialogLetters")

local MAX_MESSAGES = 3          -- max lines shown at once
local ROW_HEIGHT = 28           -- px per message row
local HOLD_TIME = 3.0           -- seconds a finished line stays before fade
local TYPE_SPEED_DEFAULT = 0.05 -- seconds per character
local MAX_DISTANCE = 75         -- bubble MaxDistance
local SCROLL_ANIM = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local FadeTI = TweenInfo.new(0.5, Enum.EasingStyle.Linear)
local FadeOutGoal = {TextTransparency = 1, TextStrokeTransparency = 1}

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

local function getLetterSound(letter: string): Sound?
	if not DialogSoundsFolder then return nil end
	local child = DialogSoundsFolder:FindFirstChild(letter:upper())
	if child and child:IsA("Sound") then
		return child:Clone()
	end
	return nil
end

-- Create or fetch a reusable bubble with a bottom-anchored ScrollingFrame
local function getOrCreateBubble(head: BasePart)
	local bubble = head:FindFirstChild("DialogBubble") :: BillboardGui?
	local scroller: ScrollingFrame? = nil
	local layout: UIListLayout? = nil

	if bubble and bubble:IsA("BillboardGui") then
		scroller = bubble:FindFirstChild("Messages") :: ScrollingFrame?
		layout = scroller and scroller:FindFirstChildOfClass("UIListLayout")
		if scroller and layout then
			return bubble, scroller, layout
		end
	end

	bubble = Instance.new("BillboardGui")
	bubble.Name = "DialogBubble"
	bubble.Size = UDim2.new(0, 260, 0, (ROW_HEIGHT * MAX_MESSAGES) + 8)
	bubble.StudsOffset = Vector3.new(0, 3.2, 0)
	bubble.MaxDistance = MAX_DISTANCE
	bubble.AlwaysOnTop = true
	bubble.Parent = head
	bubble:SetAttribute("Seq", 0)

	local bg = Instance.new("Frame")
	bg.Name = "BG"
	bg.BackgroundTransparency = 1
	bg.BorderSizePixel = 0
	bg.Size = UDim2.fromScale(1, 1)
	bg.Parent = bubble

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingTop = UDim.new(0, 4)
	pad.PaddingBottom = UDim.new(0, 4)
	pad.Parent = bg

	-- ScrollingFrame acts like a viewport; we pin to the bottom by scrolling to the end
	scroller = Instance.new("ScrollingFrame")
	scroller.Name = "Messages"
	scroller.BackgroundTransparency = 1
	scroller.BorderSizePixel = 0
	scroller.Size = UDim2.fromScale(1, 1)
	scroller.ClipsDescendants = true
	scroller.ScrollingEnabled = false -- we drive CanvasPosition ourselves
	scroller.ScrollBarThickness = 0
	scroller.CanvasSize = UDim2.fromOffset(0, 0)
	scroller.Parent = bg

	layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 2)
	layout.Parent = scroller

	return bubble, scroller, layout
end

local function createRow(scroller: ScrollingFrame, bubble: BillboardGui): TextLabel
	local seq = (bubble:GetAttribute("Seq") :: number) or 0
	seq += 1
	bubble:SetAttribute("Seq", seq)

	local label = Instance.new("TextLabel")
	label.Name = ("Line_%d"):format(seq)
	label.LayoutOrder = seq
	label.Size = UDim2.new(1, 0, 0, ROW_HEIGHT)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.5
	label.TextScaled = true
	label.Font = Enum.Font.Gotham
	label.Text = ""
	label.Parent = scroller

	return label
end

local function updateCanvas(scroller: ScrollingFrame, layout: UIListLayout, animate: boolean)
	-- Resize canvas to fit content
	scroller.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y)
	-- Keep view pinned to bottom (so new lines push older ones upward)
	local targetY = math.max(0, layout.AbsoluteContentSize.Y - scroller.AbsoluteSize.Y)
	if animate then
		TweenService:Create(scroller, SCROLL_ANIM, {CanvasPosition = Vector2.new(0, targetY)}):Play()
	else
		scroller.CanvasPosition = Vector2.new(0, targetY)
	end
end

local function enforceMax(scroller: ScrollingFrame, layout: UIListLayout)
	local labels = {}
	for _, child in ipairs(scroller:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	if #labels <= MAX_MESSAGES then return end
	table.sort(labels, function(a, b) return a.LayoutOrder < b.LayoutOrder end)
	while #labels > MAX_MESSAGES do
		labels[1]:Destroy()
		table.remove(labels, 1)
	end
	updateCanvas(scroller, layout, false)
end

function DialogTypewriter:PlayDialog(character: Model, message: string, typingSpeed: number?)
	typingSpeed = typingSpeed or TYPE_SPEED_DEFAULT
	if type(message) ~= "string" or #message == 0 then return end

	local head = character:FindFirstChild("Head")
	if not head or not head:IsA("BasePart") then return end

	local bubble, scroller, layout = getOrCreateBubble(head)
	local label = createRow(scroller, bubble)
	-- After row is added, update canvas and scroll to bottom (animate = true)
	updateCanvas(scroller, layout, true)

	-- Typewriter effect
	for i = 1, #message do
		label.Text = message:sub(1, i)

		local s = getLetterSound(message:sub(i, i))
		if s then
			s.Parent = head
			if #Effects > 0 then
				for _, effect in ipairs(Effects) do
					if effect:IsA("Instance") then effect:Clone().Parent = s end
				end
			end
			s:Play()
			Debris:AddItem(s, 2)
		end

		task.wait(typingSpeed)
		if not head.Parent then return end
	end

	-- Fade out this line after a hold, then prune & re-pin to bottom
	task.delay(HOLD_TIME, function()
		if label and label.Parent then
			local t = TweenService:Create(label, FadeTI, FadeOutGoal)
			t:Play()
			t.Completed:Wait()
			if label and label.Parent then
				label:Destroy()
				if scroller and layout then
					updateCanvas(scroller, layout, false)
				end
			end
		end
	end)

	-- Ensure we don't exceed MAX_MESSAGES
	enforceMax(scroller, layout)
end

return DialogTypewriter
