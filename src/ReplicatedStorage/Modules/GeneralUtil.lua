--!strict

local GlobalNumbers = {}

-- Distance Constants
GlobalNumbers.SNAP_DISTANCE = 5
GlobalNumbers.INTERACTION_DISTANCE = 5
GlobalNumbers.OWNERSHIP_TIMEOUT = 30
GlobalNumbers.DRAG_NETWORK_DELAY = 0.35

-- Inventory Constants
GlobalNumbers.MAX_INVENTORY_SLOTS = 5
GlobalNumbers.BASE_WALKSPEED = 16
GlobalNumbers.INVENTORY_WEIGHT_PER_SPEED = 5
GlobalNumbers.CART_WEIGHT_PER_SPEED = 10

-- Update Rates
GlobalNumbers.UPDATE_RATE = 0.1
GlobalNumbers.CHECK_INTERVAL = 2
GlobalNumbers.VISUAL_UPDATE_FREQUENCY = 0.1

-- Drag Constants
GlobalNumbers.DRAG_DISTANCE = 10
GlobalNumbers.MIN_DRAG_DISTANCE = 5
GlobalNumbers.MAX_DRAG_DISTANCE = 20
GlobalNumbers.DISTANCE_INCREMENT = 1
GlobalNumbers.UPDATE_FREQUENCY = 1/60

-- Cart Rendering
GlobalNumbers.MAX_RENDER_DISTANCE = 500
GlobalNumbers.HIGH_DETAIL_DISTANCE = 100
GlobalNumbers.MEDIUM_DETAIL_DISTANCE = 250

-- Common Math Utilities
function GlobalNumbers.Clamp(Value: number, Min: number, Max: number): number
	return math.max(Min, math.min(Max, Value))
end

function GlobalNumbers.Lerp(Start: number, End: number, Alpha: number): number
	return Start + (End - Start) * Alpha
end

function GlobalNumbers.Distance(PointA: Vector3, PointB: Vector3): number
	return (PointA - PointB).Magnitude
end

function GlobalNumbers.DistanceXZ(PointA: Vector3, PointB: Vector3): number
	local FlatA = Vector3.new(PointA.X, 0, PointA.Z)
	local FlatB = Vector3.new(PointB.X, 0, PointB.Z)
	return (FlatA - FlatB).Magnitude
end

function GlobalNumbers.Round(Value: number, DecimalPlaces: number?): number
	local Multiplier = 10 ^ (DecimalPlaces or 0)
	return math.floor(Value * Multiplier + 0.5) / Multiplier
end

function GlobalNumbers.MapRange(Value: number, InMin: number, InMax: number, OutMin: number, OutMax: number): number
	return OutMin + (Value - InMin) * (OutMax - OutMin) / (InMax - InMin)
end

function GlobalNumbers.GetAverage(Values: {number}): number
	if #Values == 0 then
		return 0
	end

	local Sum = 0
	for _, Value in pairs(Values) do
		Sum += Value
	end

	return Sum / #Values
end

return GlobalNumbers