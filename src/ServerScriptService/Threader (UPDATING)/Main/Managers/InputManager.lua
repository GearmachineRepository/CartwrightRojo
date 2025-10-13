--!strict
local UserInputService = game:GetService("UserInputService")

local InputManager = {}

local PluginGui: PluginGui? = nil
local DragSubscribers: {(Vector2, Vector2) -> ()} = {}
local PanSubscribers: {(Vector2, Vector2) -> ()} = {}
local ClickSubscribers: {(Vector2) -> ()} = {}
local ScrollSubscribers: {(number) -> ()} = {}

local IsDraggingFlag = false
local IsPanningFlag = false
local DragStartPosition: Vector2? = nil
local CurrentMousePosition = Vector2.zero

local DRAG_THRESHOLD = 5

function InputManager.Initialize(GuiObject: PluginGui)
	PluginGui = GuiObject

	UserInputService.InputBegan:Connect(function(Input, GameProcessed)
		if GameProcessed then return end

		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			DragStartPosition = Vector2.new(Input.Position.X, Input.Position.Y)
			IsDraggingFlag = false
			IsPanningFlag = false
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			DragStartPosition = Vector2.new(Input.Position.X, Input.Position.Y)
			IsPanningFlag = true
		end
	end)

	UserInputService.InputChanged:Connect(function(Input, GameProcessed)
		if Input.UserInputType == Enum.UserInputType.MouseMovement then
			CurrentMousePosition = Vector2.new(Input.Position.X, Input.Position.Y)

			if DragStartPosition then
				local Delta = CurrentMousePosition - DragStartPosition

				if not IsDraggingFlag and not IsPanningFlag and Delta.Magnitude >= DRAG_THRESHOLD then
					IsDraggingFlag = true
				end

				if IsDraggingFlag then
					for _, Callback in ipairs(DragSubscribers) do
						Callback(DragStartPosition, CurrentMousePosition)
					end
				elseif IsPanningFlag then
					for _, Callback in ipairs(PanSubscribers) do
						Callback(DragStartPosition, CurrentMousePosition)
					end
				end
			end
		elseif Input.UserInputType == Enum.UserInputType.MouseWheel then
			for _, Callback in ipairs(ScrollSubscribers) do
				Callback(Input.Position.Z)
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(Input, GameProcessed)
		if Input.UserInputType == Enum.UserInputType.MouseButton1 then
			if DragStartPosition and not IsDraggingFlag then
				for _, Callback in ipairs(ClickSubscribers) do
					Callback(CurrentMousePosition)
				end
			end

			DragStartPosition = nil
			IsDraggingFlag = false
		elseif Input.UserInputType == Enum.UserInputType.MouseButton2 then
			DragStartPosition = nil
			IsPanningFlag = false
		end
	end)
end

function InputManager.SubscribeToDrag(Callback: (Vector2, Vector2) -> ()): () -> ()
	table.insert(DragSubscribers, Callback)
	return function()
		InputManager.Unsubscribe(Callback)
	end
end

function InputManager.SubscribeToPan(Callback: (Vector2, Vector2) -> ()): () -> ()
	table.insert(PanSubscribers, Callback)
	return function()
		InputManager.Unsubscribe(Callback)
	end
end

function InputManager.SubscribeToClick(Callback: (Vector2) -> ()): () -> ()
	table.insert(ClickSubscribers, Callback)
	return function()
		InputManager.Unsubscribe(Callback)
	end
end

function InputManager.SubscribeToScroll(Callback: (number) -> ()): () -> ()
	table.insert(ScrollSubscribers, Callback)
	return function()
		InputManager.Unsubscribe(Callback)
	end
end

function InputManager.GetMousePosition(): Vector2
	return CurrentMousePosition
end

function InputManager.IsDragging(): boolean
	return IsDraggingFlag
end

function InputManager.IsPanning(): boolean
	return IsPanningFlag
end

function InputManager.Unsubscribe(Callback: any)
	local function RemoveFromTable(Table: {any})
		for Index, StoredCallback in ipairs(Table) do
			if StoredCallback == Callback then
				table.remove(Table, Index)
				return
			end
		end
	end

	RemoveFromTable(DragSubscribers)
	RemoveFromTable(PanSubscribers)
	RemoveFromTable(ClickSubscribers)
	RemoveFromTable(ScrollSubscribers)
end

return InputManager