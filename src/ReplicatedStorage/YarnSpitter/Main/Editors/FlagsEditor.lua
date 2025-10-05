--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local FlagsEditor = {}

function FlagsEditor.Render(
	Choice: DialogChoice,
	Container: Frame,
	StartOrder: number,
	OnRefresh: () -> ()
): number
	local CurrentOrder = StartOrder

	Components.CreateLabel("Set Flags (when selected):", Container, CurrentOrder)
	CurrentOrder += 1

	if not Choice.SetFlags then
		Choice.SetFlags = {}
	end

	for Index, FlagName in ipairs(Choice.SetFlags) do
		local FlagContainer = Components.CreateContainer(Container, CurrentOrder)
		CurrentOrder += 1

		Components.CreateLabel("Flag " .. tostring(Index), FlagContainer, 1)
		Components.CreateTextBox(
			FlagName,
			FlagContainer,
			2,
			false,
			function(NewName)
				Choice.SetFlags[Index] = NewName
			end
		)

		Components.CreateButton(
			"Delete Flag",
			FlagContainer,
			3,
			Constants.COLORS.Danger,
			function()
				DialogTree.RemoveFlag(Choice, Index)
				OnRefresh()
			end
		)
	end

	Components.CreateButton(
		"+ Add Flag",
		Container,
		CurrentOrder,
		Constants.COLORS.Primary,
		function()
			DialogTree.AddFlag(Choice, "NewFlag")
			OnRefresh()
		end
	)
	CurrentOrder += 1

	return CurrentOrder
end

return FlagsEditor