--!strict
local DialogText = {}

local UI = game.ReplicatedStorage:WaitForChild("UI")
local DialogUI = UI:WaitForChild("DialogUI")
local OptionUI = UI:WaitForChild("OptionsUI")

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")
local GamepadService = game:GetService("GamepadService")

local SoundEffects = SoundService:WaitForChild("Sound Effects")
local ResponseSound = SoundEffects:WaitForChild("ResponseText")
local DefaultNpcSound = SoundEffects:WaitForChild("NPCText")

local FADE_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

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
				Child:Destroy()
			end
		end
	end
	GamepadService:DisableGamepadCursor()
end

function DialogText.PlayerResponse(PlayerModel: Model, Message: string, EnableScripts: boolean): BillboardGui?
	if not Message then return nil end

	if PlayerModel:FindFirstChild("Head") then
		for _, Gui in ipairs(PlayerModel.Head:GetChildren()) do
			if Gui:IsA("BillboardGui") and Gui.Name == DialogUI.Name then
				Gui:Destroy()
			end
		end
	end

	local Gui = DialogUI:Clone()
	Gui.Parent = PlayerModel.Head
	Gui.TextLabel.Text = Message
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