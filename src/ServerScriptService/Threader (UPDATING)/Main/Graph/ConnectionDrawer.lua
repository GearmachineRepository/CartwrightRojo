--!strict
local Colors = require(script.Parent.Parent.Theme.Colors)

local ConnectionDrawer = {}

function ConnectionDrawer.DrawConnection(StartFrame: Frame, EndFrame: Frame, Parent: Frame, Color: Color3?)
	local StartPos = StartFrame.AbsolutePosition + StartFrame.AbsoluteSize / 2
	local EndPos = EndFrame.AbsolutePosition + EndFrame.AbsoluteSize / 2

	if not Parent:IsDescendantOf(game) then return end

	local ParentPos = Parent.AbsolutePosition
	local RelativeStart = StartPos - ParentPos
	local RelativeEnd = EndPos - ParentPos

	local Distance = (RelativeEnd - RelativeStart).Magnitude
	local Angle = math.atan2(RelativeEnd.Y - RelativeStart.Y, RelativeEnd.X - RelativeStart.X)

	local Line = Instance.new("Frame")
	Line.Size = UDim2.new(0, Distance, 0, 2)
	Line.Position = UDim2.fromOffset(RelativeStart.X, RelativeStart.Y)
	Line.AnchorPoint = Vector2.new(0, 0.5)
	Line.Rotation = math.deg(Angle)
	Line.BackgroundColor3 = Color or Colors.Border
	Line.BorderSizePixel = 0
	Line.ZIndex = 1
	Line.Parent = Parent

	local Arrow = Instance.new("Frame")
	Arrow.Size = UDim2.new(0, 8, 0, 8)
	Arrow.Position = UDim2.new(1, -4, 0.5, 0)
	Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	Arrow.BackgroundColor3 = Color or Colors.Border
	Arrow.BorderSizePixel = 0
	Arrow.Rotation = 45
	Arrow.Parent = Line
end

function ConnectionDrawer.DrawBezier(StartFrame: Frame, EndFrame: Frame, Parent: Frame, Color: Color3?)
	local StartPos = StartFrame.AbsolutePosition + StartFrame.AbsoluteSize / 2
	local EndPos = EndFrame.AbsolutePosition + EndFrame.AbsoluteSize / 2

	if not Parent:IsDescendantOf(game) then return end

	local ParentPos = Parent.AbsolutePosition
	local RelativeStart = StartPos - ParentPos
	local RelativeEnd = EndPos - ParentPos

	local Distance = (RelativeEnd - RelativeStart).Magnitude
	local ControlOffset = Distance * 0.4

	local Control1 = RelativeStart + Vector2.new(ControlOffset, 0)
	local Control2 = RelativeEnd - Vector2.new(ControlOffset, 0)

	local Segments = math.max(10, math.floor(Distance / 20))

	for Index = 0, Segments - 1 do
		local T1 = Index / Segments
		local T2 = (Index + 1) / Segments

		local Point1 = ConnectionDrawer.CalculateBezier(RelativeStart, Control1, Control2, RelativeEnd, T1)
		local Point2 = ConnectionDrawer.CalculateBezier(RelativeStart, Control1, Control2, RelativeEnd, T2)

		local SegmentDistance = (Point2 - Point1).Magnitude
		local SegmentAngle = math.atan2(Point2.Y - Point1.Y, Point2.X - Point1.X)

		local Segment = Instance.new("Frame")
		Segment.Size = UDim2.new(0, SegmentDistance, 0, 2)
		Segment.Position = UDim2.fromOffset(Point1.X, Point1.Y)
		Segment.AnchorPoint = Vector2.new(0, 0.5)
		Segment.Rotation = math.deg(SegmentAngle)
		Segment.BackgroundColor3 = Color or Colors.Border
		Segment.BorderSizePixel = 0
		Segment.ZIndex = 1
		Segment.Parent = Parent
	end

	local FinalPoint = ConnectionDrawer.CalculateBezier(RelativeStart, Control1, Control2, RelativeEnd, 1)
	local Arrow = Instance.new("Frame")
	Arrow.Size = UDim2.new(0, 8, 0, 8)
	Arrow.Position = UDim2.fromOffset(FinalPoint.X, FinalPoint.Y)
	Arrow.AnchorPoint = Vector2.new(0.5, 0.5)
	Arrow.BackgroundColor3 = Color or Colors.Border
	Arrow.BorderSizePixel = 0
	Arrow.Rotation = 45
	Arrow.ZIndex = 1
	Arrow.Parent = Parent
end

function ConnectionDrawer.CalculateBezier(P0: Vector2, P1: Vector2, P2: Vector2, P3: Vector2, T: number): Vector2
	local OneMinusT = 1 - T
	local OneMinusTSquared = OneMinusT * OneMinusT
	local OneMinusTCubed = OneMinusTSquared * OneMinusT
	local TSquared = T * T
	local TCubed = TSquared * T

	return Vector2.new(
		OneMinusTCubed * P0.X + 3 * OneMinusTSquared * T * P1.X + 3 * OneMinusT * TSquared * P2.X + TCubed * P3.X,
		OneMinusTCubed * P0.Y + 3 * OneMinusTSquared * T * P1.Y + 3 * OneMinusT * TSquared * P2.Y + TCubed * P3.Y
	)
end

return ConnectionDrawer