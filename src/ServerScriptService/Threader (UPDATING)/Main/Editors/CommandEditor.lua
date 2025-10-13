--!strict
local NodeEditor = require(script.Parent.NodeEditor)
local Builder = require(script.Parent.Parent.Components.Builder)

local CommandEditor = {}

function CommandEditor.RenderCommandSection(Parent: Frame, Command: string?, OnCommandChanged: (string?) -> ())
	local CommandSection, CommandContent = NodeEditor.CreateCollapsibleSection(
		Parent,
		"Commands",
		true
	)

	Builder.Label("Execute custom Lua code when this is triggered:").Parent = CommandContent

	Builder.Spacer(4).Parent = CommandContent

	Builder.LabeledInput("Lua Code:", {
		Value = Command or "",
		PlaceholderText = "print('Hello World')\nPlayer:SetAttribute('Talked', true)",
		Multiline = true,
		Height = 120,
		OnChanged = function(Text)
			OnCommandChanged(Text ~= "" and Text or nil)
		end
	}).Parent = CommandContent

	Builder.Spacer(4).Parent = CommandContent

	Builder.Label("Available variables: Player, DialogTree, Node", {
		Color = Color3.fromRGB(160, 160, 160)
	}).Parent = CommandContent

	return CommandSection
end

return CommandEditor