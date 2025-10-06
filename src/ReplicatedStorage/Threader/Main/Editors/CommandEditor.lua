--!strict
local Components = require(script.Parent.Parent.UI.Components)
local Constants = require(script.Parent.Parent.Constants)
local DialogTree = require(script.Parent.Parent.Data.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local CommandEditor = {}

local COMMON_COMMANDS = {
	"-- Set a flag",
	'DialogConditions.SetFlag(Plr, "FlagName", true)',
	"",
	"-- Give a quest",
	'QuestManager.GiveQuest(Plr, "QuestId")',
	"",
	"-- Update quest progress",
	'QuestManager.UpdateQuestProgress(Plr, "QuestId", "TalkTo", "NpcName", 1)',
	"",
	"-- Give item",
	'local Item = game.ServerStorage.Items:FindFirstChild("ItemName")',
	"if Item then",
	"    Item:Clone().Parent = Plr.Backpack",
	"end",
	"",
	"-- Turn in quest",
	'QuestManager.TurnInQuest(Plr, "QuestId")',
}

function CommandEditor.Render(
	Choice: DialogChoice,
	Container: Frame,
	StartOrder: number
): number
	local CurrentOrder = StartOrder

	Components.CreateLabel("Command (Lua code - runs when selected):", Container, CurrentOrder)
	CurrentOrder += 1

	local CommandText = Choice.Command or ""

	local CommandBox = Instance.new("TextBox")
	CommandBox.Size = UDim2.new(1, 0, 0, 120)
	CommandBox.Text = CommandText
	CommandBox.TextColor3 = Constants.COLORS.TextPrimary
	CommandBox.BackgroundColor3 = Constants.COLORS.InputBackground
	CommandBox.Font = Enum.Font.Code
	CommandBox.TextSize = 12
	CommandBox.TextXAlignment = Enum.TextXAlignment.Left
	CommandBox.TextYAlignment = Enum.TextYAlignment.Top
	CommandBox.TextWrapped = true
	CommandBox.MultiLine = true
	CommandBox.ClearTextOnFocus = false
	CommandBox.LayoutOrder = CurrentOrder
	CommandBox.Parent = Container

	local Padding = Instance.new("UIPadding")
	Padding.PaddingLeft = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.PaddingRight = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.PaddingTop = UDim.new(0, Constants.SIZES.PaddingSmall)
	Padding.Parent = CommandBox

	CommandBox.FocusLost:Connect(function()
		Choice.Command = CommandBox.Text
	end)

	CurrentOrder += 1

	Components.CreateLabel("Common Commands (click to copy):", Container, CurrentOrder)
	CurrentOrder += 1

	local ExamplesText = table.concat(COMMON_COMMANDS, "\n")
	local ExamplesLabel = Instance.new("TextLabel")
	ExamplesLabel.Size = UDim2.new(1, 0, 0, 180)
	ExamplesLabel.Text = ExamplesText
	ExamplesLabel.TextColor3 = Constants.COLORS.TextMuted
	ExamplesLabel.BackgroundColor3 = Constants.COLORS.Panel
	ExamplesLabel.Font = Enum.Font.Code
	ExamplesLabel.TextSize = 11
	ExamplesLabel.TextXAlignment = Enum.TextXAlignment.Left
	ExamplesLabel.TextYAlignment = Enum.TextYAlignment.Top
	ExamplesLabel.TextWrapped = true
	ExamplesLabel.LayoutOrder = CurrentOrder
	ExamplesLabel.Parent = Container

	local ExamplesPadding = Instance.new("UIPadding")
	ExamplesPadding.PaddingLeft = UDim.new(0, Constants.SIZES.PaddingSmall)
	ExamplesPadding.PaddingTop = UDim.new(0, Constants.SIZES.PaddingSmall)
	ExamplesPadding.Parent = ExamplesLabel

	CurrentOrder += 1

	return CurrentOrder
end

return CommandEditor