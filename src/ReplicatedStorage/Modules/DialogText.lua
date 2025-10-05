--!strict
local DialogText = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local Emitter = require(Modules:WaitForChild("Emitter"))

local UI = ReplicatedStorage:WaitForChild("UI")
local DialogUI = UI:WaitForChild("DialogUI")
local OptionUI = UI:WaitForChild("OptionsUI")

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local GamepadService = game:GetService("GamepadService")

local SoundEffects = SoundService:WaitForChild("Sound Effects")
local ResponseSound = SoundEffects:WaitForChild("ResponseText")
local DefaultNpcSound = SoundEffects:WaitForChild("NPCText")

local ActiveParticleEmitters = {}

local FADE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local SKILL_COLORS = {
	Perception = Color3.fromRGB(100, 200, 255),   -- Blue
	Empathy = Color3.fromRGB(255, 150, 200),      -- Pink
	Logic = Color3.fromRGB(200, 255, 150),        -- Green
	Authority = Color3.fromRGB(255, 100, 100),    -- Red
	Rhetoric = Color3.fromRGB(255, 200, 100),     -- Orange
	Composure = Color3.fromRGB(150, 150, 255),    -- Purple
	Endurance = Color3.fromRGB(200, 150, 100),    -- Brown
	Streetwise = Color3.fromRGB(150, 255, 150)    -- Lime
}

local SKILL_PARTICLE_COLORS = {
	Perception = Color3.fromRGB(100, 200, 255),
	Empathy = Color3.fromRGB(255, 150, 200),
	Logic = Color3.fromRGB(200, 255, 150),
	Authority = Color3.fromRGB(255, 100, 100),
	Rhetoric = Color3.fromRGB(255, 200, 100),
	Composure = Color3.fromRGB(150, 150, 255),
	Endurance = Color3.fromRGB(200, 150, 100),
	Streetwise = Color3.fromRGB(150, 255, 150)
}

local function StripSkillCheckInfo(Text: string): string
	-- Remove [Skill Difficulty] prefix
	Text = Text:gsub("%[%w+%s+%d+%]%s*", "")
	-- Remove (X%) suffix
	Text = Text:gsub("%s*%(%d+%%%)", "")
	return Text
end

local function GetSkillFromText(Text: string): string?
	local SkillName = Text:match("%[(%w+)%s+%d+%]")
	return SkillName
end

local function ColorizeSkillCheckButton(Button: Instance, Text: string)
	local SkillName = GetSkillFromText(Text)
	if SkillName and SKILL_COLORS[SkillName] then
		local Frame = Button:FindFirstChild("Frame")
		if Frame and Frame:FindFirstChild("ImageButton") then
			Frame.ImageLabel.ImageColor3 = SKILL_COLORS[SkillName]
		end
	end
end

local function CreateSkillParticleTemplate(SkillColor: Color3): Frame
	local ParticleTemplate = Instance.new("Frame")
	ParticleTemplate.Name = "SkillParticle"
	ParticleTemplate.Size = UDim2.fromOffset(4, 4)
	ParticleTemplate.BackgroundColor3 = SkillColor
	ParticleTemplate.BackgroundTransparency = 0  -- Set initial value
	ParticleTemplate.BorderSizePixel = 0
	ParticleTemplate.Visible = false
	ParticleTemplate.AnchorPoint = Vector2.new(0.5, 0.5)

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(1, 0)
	Corner.Parent = ParticleTemplate

	return ParticleTemplate
end

local function AddSkillParticles(Button: Instance, SkillName: string)
	local Frame = Button:FindFirstChild("Frame")
	if not Frame then return end

	local ImageButton = Frame:FindFirstChild("ImageButton")
	if not ImageButton then return end

	local ParticleColor = SKILL_PARTICLE_COLORS[SkillName]
	if not ParticleColor then return end

	local ParticleEmitter = Emitter.newEmitter(ImageButton)
	local ParticleTemplate = CreateSkillParticleTemplate(ParticleColor)

	ParticleEmitter
		:SetEmitterParticle(ParticleTemplate)
		:SetEmitterRate(3)
		:SetSpeed(20, 40)
		:SetLifetime(1, 2)
		:SetSpreadAngle(0, 360)
		:SetRotationSpeed(-0.5, 0.5)
		:SetDrag(1)
		:SetScale(NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0)
		}))

	-- Try without BackgroundTransparency transition first
	-- Once this works, we can add it back

	ActiveParticleEmitters[Button] = ParticleEmitter
end

local function StripTags(Text: string): string
	return Text:gsub("<.->", "")
end

local function TypewriterEffect(TextLabel: TextLabel, IsNpc: boolean): ()
	local PlainText = StripTags(TextLabel.Text)
	local Length = #PlainText
	TextLabel.MaxVisibleGraphemes = 0

	if IsNpc then
		while Length >= 1 do
			task.wait()
			if DefaultNpcSound and (DefaultNpcSound.TimePosition > 0.07 or not DefaultNpcSound.Playing) then
				DefaultNpcSound.TimePosition = 0
				DefaultNpcSound.PlaybackSpeed = 1 + math.random(-5, 5) / 100
				DefaultNpcSound:Play()
			end
			Length -= 1
			TextLabel.MaxVisibleGraphemes += 1
		end
	else
		while Length >= 1 do
			task.wait()
			if math.floor(Length / 3) * 3 == Length or Length == #PlainText then
				local ClickSound = ResponseSound:Clone()
				ClickSound.Name = "SFX"
				ClickSound.PlaybackSpeed = 1 + math.random(-15, 15) / 100
				ClickSound.Playing = true
				ClickSound.Parent = SoundService
				Debris:AddItem(ClickSound, ClickSound.TimeLength * ClickSound.PlaybackSpeed)
			end
			Length -= 1
			TextLabel.MaxVisibleGraphemes += 1
		end
	end
end

function DialogText.NpcText(NpcModel: Model, Message: string, EnableScripts: boolean): BillboardGui
	local Gui = NpcModel.Head:FindFirstChild(DialogUI.Name) :: BillboardGui?

	if not Gui then
		Gui = DialogUI:Clone()
		Gui.Parent = NpcModel.Head
	elseif EnableScripts then
		for _, Child in ipairs(Gui:GetDescendants()) do
			if Child:IsA("Script") or Child:IsA("LocalScript") then
				Child:Destroy()
			end
		end
	end

	Gui.TextLabel.Text = Message
	TypewriterEffect(Gui.TextLabel, true)

	if EnableScripts then
		for _, TemplateScript in ipairs(DialogUI:GetDescendants()) do
			if TemplateScript:IsA("Script") or TemplateScript:IsA("LocalScript") then
				for _, GuiChild in ipairs(Gui:GetDescendants()) do
					if GuiChild.Name == TemplateScript.Parent.Name then
						local Clone = TemplateScript:Clone()
						Clone.Parent = GuiChild
						Clone.Enabled = true
					end
				end
			end
		end
	end

	return Gui
end

function DialogText.ShowChoices(Player: Player, Options: {string}): {Instance}
	local Buttons = {}
	local Gui = Player.PlayerGui:FindFirstChild("ResponseUI")

	for Index, Text in ipairs(Options) do
		local Option = OptionUI:Clone()
		Option.Parent = Gui
		Option.Frame.Frame.Text_Element.Text = "\"" .. Text .. "\""
		Option.Frame.Frame.TextLabel.Text = "#" .. tostring(Index)
		Option.Frame.Frame.Text_Element:SetAttribute("Text", Text)

		ColorizeSkillCheckButton(Option, Text)

		local SkillName = GetSkillFromText(Text)
		if SkillName then
			AddSkillParticles(Option, SkillName)
		end

		local Padding = Option.Frame.Frame.Text_Element:FindFirstChild("UIPadding")
		local Tween = TweenService:Create(Padding, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {
			PaddingLeft = UDim.new(0, 0)
		})
		Tween:Play()
		Debris:AddItem(Tween, 0.5)

		table.insert(Buttons, Option)
		task.wait(0.075)
	end

	if Buttons[1] then
		GamepadService:EnableGamepadCursor(Buttons[1])
	end

	return Buttons
end

function DialogText.TakeAwayResponses(NpcModel: Model, Player: Player): ()
	local Gui = Player.PlayerGui:FindFirstChild("ResponseUI")
	if Gui then
		for _, Child in ipairs(Gui:GetChildren()) do
			if Child.Name ~= "UIListLayout" then
				Child:Destroy()
			end
		end
	end

	for _, Child in ipairs(NpcModel.Head:GetChildren()) do
		if Child:IsA("BillboardGui") and Child.Name == DialogUI.Name then
			for _, Label in ipairs(Child:GetChildren()) do
				if Label:IsA("TextLabel") then
					TweenService:Create(Label, FADE_TWEEN, {TextTransparency = 1}):Play()
				elseif Label:IsA("ImageLabel") then
					TweenService:Create(Label, FADE_TWEEN, {ImageTransparency = 1}):Play()
				end
			end
			Debris:AddItem(Child, FADE_TWEEN.Time)
		end
	end

	if Player.Character and Player.Character:FindFirstChild("Head") then
		for _, UIElement in ipairs(Player.Character.Head:GetChildren()) do
			if UIElement:IsA("BillboardGui") and UIElement.Name == DialogUI.Name then
				for _, Label in ipairs(UIElement:GetChildren()) do
					if Label:IsA("TextLabel") then
						TweenService:Create(Label, FADE_TWEEN, {TextTransparency = 1}):Play()
					elseif Label:IsA("ImageLabel") then
						TweenService:Create(Label, FADE_TWEEN, {ImageTransparency = 1}):Play()
					end
				end
				Debris:AddItem(UIElement, FADE_TWEEN.Time)
			end
		end
	end
end

function DialogText.RemovePlayerSideFrame(Player: Player): ()
	local Gui = Player.PlayerGui:FindFirstChild("ResponseUI")
	if Gui then
		for _, Child in ipairs(Gui:GetChildren()) do
			if Child.Name ~= "UIListLayout" then
				-- Clear particles but don't destroy emitter
				if ActiveParticleEmitters[Child] then
					ActiveParticleEmitters[Child]:ClearParticles()
					ActiveParticleEmitters[Child]:SetEmitterParticle(nil)
					ActiveParticleEmitters[Child] = nil
				end
				Child:Destroy()
			end
		end
	end
	GamepadService:DisableGamepadCursor()
end

function DialogText.PlayerResponse(PlayerModel: Model, Message: string, EnableScripts: boolean): BillboardGui?
	-- Strip skill check info from player's spoken dialog
	local CleanMessage = StripSkillCheckInfo(Message)

	if not PlayerModel or not PlayerModel:FindFirstChild("Head") then
		return nil
	end

	local Gui = PlayerModel.Head:FindFirstChild(DialogUI.Name) :: BillboardGui?

	if not Gui then
		Gui = DialogUI:Clone()
		Gui.Parent = PlayerModel.Head
	elseif EnableScripts then
		for _, Child in ipairs(Gui:GetDescendants()) do
			if Child:IsA("Script") or Child:IsA("LocalScript") then
				Child:Destroy()
			end
		end
	end

	Gui.TextLabel.Text = CleanMessage  -- Use cleaned message
	TypewriterEffect(Gui.TextLabel, false)

	if EnableScripts then
		for _, TemplateScript in ipairs(DialogUI:GetDescendants()) do
			if TemplateScript:IsA("Script") or TemplateScript:IsA("LocalScript") then
				for _, GuiChild in ipairs(Gui:GetDescendants()) do
					if GuiChild.Name == TemplateScript.Parent.Name then
						local Clone = TemplateScript:Clone()
						Clone.Parent = GuiChild
						Clone.Enabled = true
					end
				end
			end
		end
	end

	return Gui
end

return DialogText