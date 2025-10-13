--!strict
local Colors = require(script.Parent.Parent.Theme.Colors)
local Fonts = require(script.Parent.Parent.Theme.Fonts)
local Spacing = require(script.Parent.Parent.Theme.Spacing)
local Builder = require(script.Parent.Parent.Components.Builder)
local ZIndexManager = require(script.Parent.Parent.Managers.ZIndexManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)

local ModalView = {}

function ModalView.CreateTextInput(Parent: GuiObject, Title: string, Prompt: string, DefaultValue: string, OnConfirm: (string) -> ()): Frame
	local Connections = ConnectionManager.Create()

	local Overlay = Instance.new("Frame")
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	Overlay.BackgroundTransparency = 0.5
	Overlay.BorderSizePixel = 0
	Overlay.Parent = Parent

	ZIndexManager.SetLayer(Overlay, "Modal")

	local Modal = Builder.Panel({
		Title = Title,
		Width = 400,
		Height = 200
	})
	Modal.Position = UDim2.new(0.5, -200, 0.5, -100)
	Modal.Parent = Overlay

	ZIndexManager.SetLayer(Modal, "Modal")

	local PromptLabel = Builder.Label(Prompt)
	PromptLabel.LayoutOrder = 1
	PromptLabel.Parent = Modal

	Builder.Spacer(8).Parent = Modal

	local InputBox = Builder.TextBox({
		Value = DefaultValue,
		PlaceholderText = Prompt
	})
	InputBox.LayoutOrder = 3
	InputBox.Text = DefaultValue
	InputBox.Parent = Modal

	Builder.Spacer(16).Parent = Modal

	local ButtonContainer = Builder.ButtonRow({})
	ButtonContainer.LayoutOrder = 5
	ButtonContainer.Parent = Modal

	local CancelButton = Builder.Button({
		Text = "Cancel",
		OnClick = function()
			Connections:Cleanup()
			Overlay:Destroy()
		end
	})
	CancelButton.Parent = ButtonContainer

	local ConfirmButton = Builder.Button({
		Text = "Confirm",
		Type = "Success",
		OnClick = function()
			local Value = InputBox.Text
			Connections:Cleanup()
			Overlay:Destroy()
			OnConfirm(Value)
		end
	})
	ConfirmButton.Parent = ButtonContainer

	task.wait()
	InputBox:CaptureFocus()

	Connections:Add(InputBox.FocusLost:Connect(function(EnterPressed)
		if EnterPressed then
			local Value = InputBox.Text
			Connections:Cleanup()
			Overlay:Destroy()
			OnConfirm(Value)
		end
	end))

	return Overlay
end

function ModalView.CreateConfirmation(Parent: GuiObject, Title: string, Message: string, OnConfirm: () -> (), OnCancel: (() -> ())?): Frame
	local Connections = ConnectionManager.Create()

	local Overlay = Instance.new("Frame")
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundColor3 = Color3.new(0, 0, 0)
	Overlay.BackgroundTransparency = 0.5
	Overlay.BorderSizePixel = 0
	Overlay.Parent = Parent

	ZIndexManager.SetLayer(Overlay, "Modal")

	local Modal = Builder.Panel({
		Title = Title,
		Width = 400,
		Height = 180
	})
	Modal.Position = UDim2.new(0.5, -200, 0.5, -90)
	Modal.Parent = Overlay

	ZIndexManager.SetLayer(Modal, "Modal")

	local MessageLabel = Builder.Label(Message)
	MessageLabel.LayoutOrder = 1
	MessageLabel.TextWrapped = true
	MessageLabel.Size = UDim2.new(1, 0, 0, 60)
	MessageLabel.Parent = Modal

	Builder.Spacer(16).Parent = Modal

	local ButtonContainer = Builder.ButtonRow({})
	ButtonContainer.LayoutOrder = 3
	ButtonContainer.Parent = Modal

	local CancelButton = Builder.Button({
		Text = "Cancel",
		OnClick = function()
			Connections:Cleanup()
			Overlay:Destroy()
			if OnCancel then
				OnCancel()
			end
		end
	})
	CancelButton.Parent = ButtonContainer

	local ConfirmButton = Builder.Button({
		Text = "Confirm",
		Type = "Danger",
		OnClick = function()
			Connections:Cleanup()
			Overlay:Destroy()
			OnConfirm()
		end
	})
	ConfirmButton.Parent = ButtonContainer

	return Overlay
end

function ModalView.CreateNotification(Parent: GuiObject, Title: string, Message: string, Duration: number?): Frame
	local Overlay = Instance.new("Frame")
	Overlay.Size = UDim2.fromScale(1, 1)
	Overlay.BackgroundTransparency = 1
	Overlay.Parent = Parent

	ZIndexManager.SetLayer(Overlay, "Overlay")

	local Notification = Builder.Panel({
		Title = Title,
		Width = 350,
		Height = 120
	})
	Notification.Position = UDim2.new(0.5, -175, 0, -150)
	Notification.Parent = Overlay

	ZIndexManager.SetLayer(Notification, "Overlay")

	local MessageLabel = Builder.Label(Message)
	MessageLabel.LayoutOrder = 1
	MessageLabel.TextWrapped = true
	MessageLabel.Size = UDim2.new(1, 0, 0, 40)
	MessageLabel.Parent = Notification

	Notification:TweenPosition(
		UDim2.new(0.5, -175, 0, 20),
		Enum.EasingDirection.Out,
		Enum.EasingStyle.Back,
		0.3,
		true
	)

	task.delay(Duration or 3, function()
		Notification:TweenPosition(
			UDim2.new(0.5, -175, 0, -150),
			Enum.EasingDirection.In,
			Enum.EasingStyle.Quad,
			0.3,
			true,
			function()
				Overlay:Destroy()
			end
		)
	end)

	return Overlay
end

return ModalView