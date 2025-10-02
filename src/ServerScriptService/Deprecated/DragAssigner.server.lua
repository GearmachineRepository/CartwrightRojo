local CollectionService = game:GetService("CollectionService")

-- Constants
local DRAG_TAG: string = "Drag"

local Interactables = workspace:WaitForChild("Draggables")

-- Function to make a model draggable
local function MakeModelDraggable(Model: Model): ()
	CollectionService:AddTag(Model, DRAG_TAG)

	-- Ensure the model has a PrimaryPart set
	if not Model.PrimaryPart then
		Model.PrimaryPart = Model:FindFirstChildWhichIsA("BasePart")
	end
end

for Index, Draggable in pairs(Interactables:GetChildren()) do
	if Draggable:IsA("Model") then
		MakeModelDraggable(Draggable)
	end
end

