--!strict
local ZIndexManager = {}

local LAYER_RANGES = {
	Base = {Min = 1, Max = 99},
	UI = {Min = 100, Max = 199},
	Modal = {Min = 200, Max = 299},
	Overlay = {Min = 300, Max = 399}
}

local OriginalZIndices: {[GuiObject]: number} = {}

function ZIndexManager.Initialize()
	OriginalZIndices = {}
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

	local function UpdateDescendants(Parent: GuiObject, Depth: number)
		for _, Descendant in ipairs(Parent:GetDescendants()) do
			if Descendant:IsA("GuiObject") then
				if not OriginalZIndices[Descendant] then
					OriginalZIndices[Descendant] = Descendant.ZIndex
				end
				Descendant.ZIndex = BaseZIndex + Depth
			end
		end
	end

	UpdateDescendants(Element, 1)
end

function ZIndexManager.Elevate(Element: GuiObject, Layer: string)
	ZIndexManager.SetLayer(Element, Layer)
end

function ZIndexManager.Reset(Element: GuiObject)
	local OriginalZIndex = OriginalZIndices[Element]
	if OriginalZIndex then
		Element.ZIndex = OriginalZIndex
		OriginalZIndices[Element] = nil
	end

	for _, Descendant in ipairs(Element:GetDescendants()) do
		if Descendant:IsA("GuiObject") then
			local DescendantOriginalZIndex = OriginalZIndices[Descendant]
			if DescendantOriginalZIndex then
				Descendant.ZIndex = DescendantOriginalZIndex
				OriginalZIndices[Descendant] = nil
			end
		end
	end
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