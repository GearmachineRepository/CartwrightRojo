--!strict
local PlacementFootprint = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local ObjectDatabase = require(Modules:WaitForChild("ObjectDatabase"))

export type Footprint = Vector2

-- Get footprint for an instance (checks multiple sources)
function PlacementFootprint.GetFootprint(target: Instance): Footprint
	-- Per-instance override via GridW/GridH attributes (highest priority)
	local gw = target:GetAttribute("GridW")
	local gh = target:GetAttribute("GridH")
	if typeof(gw) == "number" and typeof(gh) == "number" then
		local w = math.max(1, math.floor(gw + 0.5))
		local h = math.max(1, math.floor(gh + 0.5))
		return Vector2.new(w, h)
	end

	-- Vector2 attribute
	local attr = target:GetAttribute("GridFootprint")
	if typeof(attr) == "Vector2" then
		local w = math.max(1, math.floor(attr.X + 0.5))
		local h = math.max(1, math.floor(attr.Y + 0.5))
		return Vector2.new(w, h)
	end

	-- ObjectDatabase lookup
	if target.Name and ObjectDatabase then
		local cfg = ObjectDatabase.GetObjectConfig(target.Name)
		if cfg then
			if cfg.GridFootprint and typeof(cfg.GridFootprint) == "Vector2" then
				local w = math.max(1, math.floor(cfg.GridFootprint.X + 0.5))
				local h = math.max(1, math.floor(cfg.GridFootprint.Y + 0.5))
				return Vector2.new(w, h)
			end
			if cfg.CellsToOccupy and typeof(cfg.CellsToOccupy) == "number" then
				local n = math.max(1, math.floor(cfg.CellsToOccupy + 0.5))
				local r = math.floor(math.sqrt(n) + 0.5)
				return (r*r == n) and Vector2.new(r, r) or Vector2.new(n, 1)
			end
		end
	end

	-- Default fallback
	return Vector2.new(1, 1)
end

-- Apply rotation to footprint dimensions (90/270 degrees swap X/Y)
function PlacementFootprint.ApplyRotation(footprint: Footprint, rotationDegrees: number?): Footprint
	if not rotationDegrees then
		return footprint
	end

	local normalizedRot = math.round(rotationDegrees / 90) % 4

	-- If rotated 90 or 270 degrees, swap X and Y dimensions
	if normalizedRot == 1 or normalizedRot == 3 then
		return Vector2.new(footprint.Y, footprint.X)
	end

	return footprint
end

-- Calculate required cell count for a footprint
function PlacementFootprint.GetCellCount(footprint: Footprint): number
	return footprint.X * footprint.Y
end

-- Validate footprint is within reasonable bounds
function PlacementFootprint.IsValidFootprint(footprint: Footprint): boolean
	return footprint.X >= 1 and footprint.Y >= 1 
		and footprint.X <= 10 and footprint.Y <= 10
end

return PlacementFootprint