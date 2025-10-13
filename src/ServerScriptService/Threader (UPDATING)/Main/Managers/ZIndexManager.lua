--!strict
local ZIndexManager = {}

local LAYER_RANGES = {
	Base = {Min = 1, Max = 99},
	UI = {Min = 100, Max = 199},
	Modal = {Min = 200, Max = 299},
	Overlay = {Min = 300, Max = 399}
}

local OriginalZIndices: {[GuiObject]: number} = {}
local LayerConnections: {[GuiObject]: RBXScriptConnection} = {}

function ZIndexManager.Initialize()
	OriginalZIndices = {}
	for Element, Connection in pairs(LayerConnections) do
		Connection:Disconnect()
	end
	LayerConnections = {}
end

function ZIndexManager.SetLayer(Element: GuiObject, Layer: string)
	if not LAYER_RANGES[Layer] then
		warn("[ZIndexManager] Invalid layer:", Layer)
		return
	end

	if not OriginalZIndices[Element] then
		OriginalZIndices[Element] = Element.ZIndex
	end

	local BaseZIndex = LAYER_RANGES[Layer].Min
	Element.ZIndex = BaseZIndex

	local function UpdateDescendants(Parent: GuiObject, CurrentDepth: number)
		for _, Child in ipairs(Parent:GetChildren()) do
			if Child:IsA("GuiObject") then
				if not OriginalZIndices[Child] then
					OriginalZIndices[Child] = Child.ZIndex
				end
				Child.ZIndex = BaseZIndex + CurrentDepth
				UpdateDescendants(Child, CurrentDepth + 1)
			end
		end
	end

	local function SetupChildAddedConnection(Parent: GuiObject, Depth: number)
		if LayerConnections[Parent] then
			LayerConnections[Parent]:Disconnect()
		end

		LayerConnections[Parent] = Parent.ChildAdded:Connect(function(Child)
			if Child:IsA("GuiObject") then
				if not OriginalZIndices[Child] then
					OriginalZIndices[Child] = Child.ZIndex
				end
				Child.ZIndex = BaseZIndex + Depth
				UpdateDescendants(Child, Depth + 1)
				SetupChildAddedConnection(Child, Depth + 1)
			end
		end)

		for _, Child in ipairs(Parent:GetChildren()) do
			if Child:IsA("GuiObject") then
				SetupChildAddedConnection(Child, Depth + 1)
			end
		end
	end

	UpdateDescendants(Element, 1)
	SetupChildAddedConnection(Element, 1)
end

function ZIndexManager.Elevate(Element: GuiObject, Layer: string)
	ZIndexManager.SetLayer(Element, Layer)
end

function ZIndexManager.Reset(Element: GuiObject)
	if LayerConnections[Element] then
		LayerConnections[Element]:Disconnect()
		LayerConnections[Element] = nil
	end

	local OriginalZIndex = OriginalZIndices[Element]
	if OriginalZIndex then
		Element.ZIndex = OriginalZIndex
		OriginalZIndices[Element] = nil
	end

	local function ResetDescendants(Parent: GuiObject)
		for _, Child in ipairs(Parent:GetChildren()) do
			if Child:IsA("GuiObject") then
				if LayerConnections[Child] then
					LayerConnections[Child]:Disconnect()
					LayerConnections[Child] = nil
				end

				local ChildOriginalZIndex = OriginalZIndices[Child]
				if ChildOriginalZIndex then
					Child.ZIndex = ChildOriginalZIndex
					OriginalZIndices[Child] = nil
				end
				ResetDescendants(Child)
			end
		end
	end

	ResetDescendants(Element)
end

function ZIndexManager.GetLayer(Element: GuiObject): string
	local ZIndex = Element.ZIndex

	for LayerName, Range in pairs(LAYER_RANGES) do
		if ZIndex >= Range.Min and ZIndex <= Range.Max then
			return LayerName
		end
	end

	return "Unknown"
end

return ZIndexManager