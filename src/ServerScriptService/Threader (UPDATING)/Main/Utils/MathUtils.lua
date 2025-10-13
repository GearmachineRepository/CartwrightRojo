--!strict
local MathUtils = {}

function MathUtils.Lerp(A: number, B: number, T: number): number
	return A + (B - A) * T
end

function MathUtils.LerpVector2(A: Vector2, B: Vector2, T: number): Vector2
	return Vector2.new(
		MathUtils.Lerp(A.X, B.X, T),
		MathUtils.Lerp(A.Y, B.Y, T)
	)
end

function MathUtils.Clamp(Value: number, Min: number, Max: number): number
	return math.max(Min, math.min(Max, Value))
end

function MathUtils.Distance(A: Vector2, B: Vector2): number
	local DeltaX = B.X - A.X
	local DeltaY = B.Y - A.Y
	return math.sqrt(DeltaX * DeltaX + DeltaY * DeltaY)
end

function MathUtils.Normalize(Vector: Vector2): Vector2
	local Magnitude = math.sqrt(Vector.X * Vector.X + Vector.Y * Vector.Y)
	if Magnitude == 0 then
		return Vector2.new(0, 0)
	end
	return Vector2.new(Vector.X / Magnitude, Vector.Y / Magnitude)
end

function MathUtils.Angle(A: Vector2, B: Vector2): number
	return math.atan2(B.Y - A.Y, B.X - A.X)
end

function MathUtils.RoundToNearest(Value: number, Multiple: number): number
	return math.floor((Value + Multiple / 2) / Multiple) * Multiple
end

function MathUtils.MapRange(Value: number, InMin: number, InMax: number, OutMin: number, OutMax: number): number
	return OutMin + (Value - InMin) * (OutMax - OutMin) / (InMax - InMin)
end

function MathUtils.IsPointInRect(Point: Vector2, RectPosition: Vector2, RectSize: Vector2): boolean
	return Point.X >= RectPosition.X and
		Point.X <= RectPosition.X + RectSize.X and
		Point.Y >= RectPosition.Y and
		Point.Y <= RectPosition.Y + RectSize.Y
end

return MathUtils