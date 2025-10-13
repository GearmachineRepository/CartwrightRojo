--!strict
local NodeEditor = require(script.Parent.NodeEditor)
local Builder = require(script.Parent.Parent.Components.Builder)
local FlagsManagerWindow = require(script.Parent.Parent.Windows.FlagsManagerWindow)

local FlagsEditor = {}

function FlagsEditor.RenderFlagsSection(Parent: Frame, FlagsSet: {string}?, FlagsRemoved: {string}?, OnFlagsSetChanged: ({string}) -> (), OnFlagsRemovedChanged: ({string}) -> ())
	local FlagsSection, FlagsContent = NodeEditor.CreateCollapsibleSection(
		Parent,
		"Flags",
		true
	)

	local SetSection = NodeEditor.CreateSection(FlagsContent, "Flags to Set", 1)

	if not FlagsSet then
		FlagsSet = {}
	end

	local AvailableFlags = FlagsManagerWindow.GetFlags()

	if #FlagsSet > 0 then
		for Index, Flag in ipairs(FlagsSet) do
			local FlagRow = Instance.new("Frame")
			FlagRow.Size = UDim2.new(1, 0, 0, 32)
			FlagRow.BackgroundTransparency = 1
			FlagRow.Parent = SetSection

			local Layout = Instance.new("UIListLayout")
			Layout.FillDirection = Enum.FillDirection.Horizontal
			Layout.Padding = UDim.new(0, 8)
			Layout.Parent = FlagRow

			local FlagLabel = Builder.Label(Flag)
			FlagLabel.Size = UDim2.new(1, -80, 1, 0)
			FlagLabel.Parent = FlagRow

			local RemoveButton = Builder.Button({
				Text = "Remove",
				Type = "Danger",
				OnClick = function()
					table.remove(FlagsSet, Index)
					OnFlagsSetChanged(FlagsSet)
				end
			})
			RemoveButton.Size = UDim2.new(0, 70, 0, 28)
			RemoveButton.Parent = FlagRow
		end
	end

	Builder.Spacer(4).Parent = SetSection

	Builder.Dropdown({
		Label = "Add Flag to Set:",
		Options = AvailableFlags,
		Selected = "None",
		OnSelected = function(Flag)
			if Flag ~= "None" and not table.find(FlagsSet, Flag) then
				table.insert(FlagsSet, Flag)
				OnFlagsSetChanged(FlagsSet)
			end
		end
	}).Parent = SetSection

	Builder.Spacer(8).Parent = FlagsContent

	local RemoveSection = NodeEditor.CreateSection(FlagsContent, "Flags to Remove", 2)

	if not FlagsRemoved then
		FlagsRemoved = {}
	end

	if #FlagsRemoved > 0 then
		for Index, Flag in ipairs(FlagsRemoved) do
			local FlagRow = Instance.new("Frame")
			FlagRow.Size = UDim2.new(1, 0, 0, 32)
			FlagRow.BackgroundTransparency = 1
			FlagRow.Parent = RemoveSection

			local Layout = Instance.new("UIListLayout")
			Layout.FillDirection = Enum.FillDirection.Horizontal
			Layout.Padding = UDim.new(0, 8)
			Layout.Parent = FlagRow

			local FlagLabel = Builder.Label(Flag)
			FlagLabel.Size = UDim2.new(1, -80, 1, 0)
			FlagLabel.Parent = FlagRow

			local RemoveButton = Builder.Button({
				Text = "Remove",
				Type = "Danger",
				OnClick = function()
					table.remove(FlagsRemoved, Index)
					OnFlagsRemovedChanged(FlagsRemoved)
				end
			})
			RemoveButton.Size = UDim2.new(0, 70, 0, 28)
			RemoveButton.Parent = FlagRow
		end
	end

	Builder.Spacer(4).Parent = RemoveSection

	Builder.Dropdown({
		Label = "Add Flag to Remove:",
		Options = AvailableFlags,
		Selected = "None",
		OnSelected = function(Flag)
			if Flag ~= "None" and not table.find(FlagsRemoved, Flag) then
				table.insert(FlagsRemoved, Flag)
				OnFlagsRemovedChanged(FlagsRemoved)
			end
		end
	}).Parent = RemoveSection

	return FlagsSection
end

return FlagsEditor