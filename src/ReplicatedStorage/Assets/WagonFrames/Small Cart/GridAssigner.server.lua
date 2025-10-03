local Folder = script.Parent:WaitForChild("Wagon"):WaitForChild("PlacementGrid"):WaitForChild("WagonStorage")
assert(Folder and Folder:IsA("Folder"), "Select an Area Folder containing the cell BaseParts")

local Cells = {}
for _, Child in ipairs(Folder:GetDescendants()) do
	if Child:IsA("BasePart") and Child.Name ~= "Origin" then
		table.insert(Cells, Child)
	end
end
assert(#Cells > 0, ("No BaseParts found under folder '%s'"):format(Folder:GetFullName()))

local OriginPart = Folder:FindFirstChild("Origin")
local BaseCFrame
local UseOrigin = false
if OriginPart and OriginPart:IsA("BasePart") then
	BaseCFrame = OriginPart.CFrame
	UseOrigin = true
else
	local FirstCell = Cells[1]
	BaseCFrame = FirstCell.CFrame
end

local function ToUV(Position: Vector3)
	local Relative = BaseCFrame:PointToObjectSpace(Position)
	return Relative.X, -Relative.Z
end

local UVCoordinates = table.create(#Cells)
for Index, Cell in ipairs(Cells) do
	local UCoord, VCoord = ToUV(Cell.Position)
	UVCoordinates[Index] = {U = UCoord, V = VCoord, Part = Cell}
end

local function InferStep(Values: {number})
	table.sort(Values)
	local Deltas = {}
	for Index = 2, #Values do
		local Delta = math.abs(Values[Index] - Values[Index - 1])
		if Delta > 1e-3 then
			table.insert(Deltas, Delta)
		end
	end
	if #Deltas == 0 then return 1 end
	table.sort(Deltas)
	
	local SampleCount = math.max(1, math.floor(#Deltas / 3))
	local Accumulator = 0
	for Index = 1, SampleCount do
		Accumulator += Deltas[Index]
	end
	return Accumulator / SampleCount
end

local UValues, VValues = {}, {}
for Index = 1, #UVCoordinates do
	UValues[Index] = UVCoordinates[Index].U
	VValues[Index] = UVCoordinates[Index].V
end
local DeltaU = InferStep(UValues)
local DeltaV = InferStep(VValues)

local CellWidth = OriginPart and OriginPart:FindFirstChild("CellW")
local CellHeight = OriginPart and OriginPart:FindFirstChild("CellH")
if CellWidth and CellWidth:IsA("NumberValue") and CellWidth.Value > 0 then
	DeltaU = CellWidth.Value
end
if CellHeight and CellHeight:IsA("NumberValue") and CellHeight.Value > 0 then
	DeltaV = CellHeight.Value
end

local MinU, MaxU = math.huge, -math.huge
local MinV, MaxV = math.huge, -math.huge
for Index = 1, #UVCoordinates do
	local UCoord = UVCoordinates[Index].U
	local VCoord = UVCoordinates[Index].V
	if UCoord < MinU then 
		MinU = UCoord 
	end
	if UCoord > MaxU then 
		MaxU = UCoord 
	end
	if VCoord < MinV then 
		MinV = VCoord 
	end
	if VCoord > MaxV then 
		MaxV = VCoord 
	end
end

local function NormalizeUV(UCoord: number, VCoord: number): (number, number)
	if UseOrigin then
		return UCoord, VCoord
	else
		return UCoord - MinU, VCoord - MinV
	end
end

local function SnapToGrid(Value: number, Step: number): number
	return math.floor((Value / Step) + 0.5)
end

local GridMap = {}
for Index = 1, #UVCoordinates do
	local Entry = UVCoordinates[Index]
	local NormU, NormV = NormalizeUV(Entry.U, Entry.V)
	local GridX = SnapToGrid(NormU, DeltaU)
	local GridY = SnapToGrid(NormV, DeltaV)
	
	Entry.Part:SetAttribute("GridX", GridX)
	Entry.Part:SetAttribute("GridY", GridY)
	Entry.Part.Name = "PlacementCell"
	
	local Key = GridX .. "," .. GridY
	if GridMap[Key] then
		warn(string.format("Collision at (%d,%d): %s vs %s", GridX, GridY, Entry.Part:GetFullName(), GridMap[Key]:GetFullName()))
	else
		GridMap[Key] = Entry.Part
	end
end

print(string.format("Grid assignment complete: %d cells, step=(%.2f, %.2f)", #Cells, DeltaU, DeltaV))