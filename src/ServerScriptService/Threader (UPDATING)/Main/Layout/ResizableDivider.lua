--!strict
local Colors = require(script.Parent.Parent.Theme.Colors)
local InputManager = require(script.Parent.Parent.Managers.InputManager)
local ConnectionManager = require(script.Parent.Parent.Managers.ConnectionManager)

local ResizableDivider = {}

function ResizableDivider.Create(Parent: Frame, OnMoved: (number) -> ()): Frame
	local Connections = ConnectionManager.Create()

	local Divider = Instance.new("Frame")
	Divider.Size = UDim2.new(0, 4, 1, -30)
	Divider.Position = UDim2.fromOffset(250, 30)
	Divider.BackgroundColor3 = Colors.Border
	Divider.BorderSizePixel = 0
	Divider.Parent = Parent

	local DragHandle = Instance.new("TextButton")
	DragHandle.Size = UDim2.fromScale(1, 1)
	DragHandle.BackgroundTransparency = 1
	DragHandle.Text = ""
	DragHandle.Parent = Divider

	local IsDragging = false
	local OriginalPosition = 250

	Connections:Add(InputManager.SubscribeToDrag(function(StartPos: Vector2, CurrentPos: Vector2)
		if IsDragging then
			local DeltaX = CurrentPos.X - StartPos.X
			local NewPosition = math.clamp(OriginalPosition + DeltaX, 150, 500)

			Divider.Position = UDim2.fromOffset(NewPosition, 30)
			OnMoved(NewPosition)
		end
	end))

	Connections:Add(DragHandle.MouseButton1Down:Connect(function()
		IsDragging = true
		OriginalPosition = Divider.Position.X.Offset
	end))

	Connections:Add(DragHandle.MouseButton1Up:Connect(function()
		IsDragging = false
	end))

	Connections:Add(DragHandle.MouseEnter:Connect(function()
		Divider.BackgroundColor3 = Colors.Primary
	end))

	Connections:Add(DragHandle.MouseLeave:Connect(function()
		if not IsDragging then
			Divider.BackgroundColor3 = Colors.Border
		end
	end))

	return Divider
end

return ResizableDivider