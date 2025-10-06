--!strict
local BezierDrawer = {}

local ZoomHandler = require(script.Parent.ZoomHandler)

function BezierDrawer.DrawCurve(
	Thickness: number,
	Offset: number,
	StartPos: Vector2,
	EndPos: Vector2,
	LineColor: Color3,
	Parent: Frame
): {Frame}
	local lines = {}

	local function createLine(): Frame
		local line = Instance.new("Frame")
		line.BorderSizePixel = 0
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = LineColor
		line.ZIndex = 2
		line.Size = UDim2.fromOffset(0, 0)
		line.Parent = Parent
		table.insert(lines, line)
		return line
	end

	local scale = (ZoomHandler.CurrentZoom) or 1
	scale = math.max(scale, 0.0001)

	local function drawStraight(a: Vector2, b: Vector2, baseThickness: number)
		local d = b - a
		local mid = (a + b) / 2
		local screenThickness = baseThickness / scale

		local line = createLine()
		line.Position = UDim2.fromOffset(mid.X, mid.Y)
		line.Size = UDim2.fromOffset(math.ceil(d.Magnitude + screenThickness * 0.5), screenThickness)
		line.Rotation = math.deg(math.atan2(d.Y, d.X))
	end

	local function smoothstep(t: number): number
		return t * t * (3 - 2 * t)
	end

	local function drawBezier()
		local delta = EndPos - StartPos
		local dx = math.abs(delta.X)

		-- Tame the curve: tension scales with horizontal distance and a bit with upward linking.
		local CURVE_TENSION = 0.45 -- lower = straighter
		local MIN_BEND = 24
		local MAX_BEND = 180

		local baseBend = (dx * 0.35 + math.max(0, -delta.Y) * 0.25) * CURVE_TENSION
		local bend = math.clamp(baseBend + Offset * 0.25, MIN_BEND, MAX_BEND)

		-- Ease the bend down for very short links
		local t = math.clamp(dx / 300, 0, 1)
		bend *= smoothstep(t)

		local offset2d = Vector2.new(0, bend)
		local c1 = StartPos + offset2d
		local c2 = EndPos - offset2d

		local pts = table.create(25)
		local segments = 24
		for i = 0, segments do
			local u = i / segments

			local ax = StartPos.X + (c1.X - StartPos.X) * u
			local bx = c1.X      + (c2.X - c1.X)       * u
			local cx = c2.X      + (EndPos.X - c2.X)   * u

			local ay = StartPos.Y + (c1.Y - StartPos.Y) * u
			local by = c1.Y      + (c2.Y - c1.Y)       * u
			local cy = c2.Y      + (EndPos.Y - c2.Y)   * u

			local abx = ax + (bx - ax) * u
			local bcx = bx + (cx - bx) * u
			local x   = abx + (bcx - abx) * u

			local aby = ay + (by - ay) * u
			local bcy = by + (cy - by) * u
			local y   = aby + (bcy - aby) * u

			pts[#pts+1] = Vector2.new(x, y)
		end

		for i = 2, #pts do
			drawStraight(pts[i - 1], pts[i], Thickness)
		end
	end

	drawBezier()
	return lines
end


return BezierDrawer