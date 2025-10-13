--!strict
local NodeEditor = require(script.Parent.NodeEditor)
local Builder = require(script.Parent.Parent.Components.Builder)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local QuestTurnInEditor = {}

function QuestTurnInEditor.Render(Parent: ScrollingFrame, Choice: DialogChoice, OnRefresh: () -> ())
	local Base = NodeEditor.CreateBase(Parent, "Quest Turn-In Editor")

	if not Choice.QuestTurnIn then
		Choice.QuestTurnIn = {
			QuestId = "",
			SuccessText = "",
			FailureText = ""
		}
	end

	local BasicSection = NodeEditor.CreateSection(Base.Container, "Quest Turn-In", 1)

	Builder.LabeledInput("Button Text:", {
		Value = Choice.Text,
		PlaceholderText = "I completed your quest...",
		OnChanged = function(Text)
			Choice.Text = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.LabeledInput("Quest ID:", {
		Value = Choice.QuestTurnIn.QuestId,
		PlaceholderText = "Enter quest ID...",
		OnChanged = function(Text)
			Choice.QuestTurnIn.QuestId = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.LabeledInput("Success Text:", {
		Value = Choice.QuestTurnIn.SuccessText,
		PlaceholderText = "Excellent work! Here's your reward.",
		Multiline = true,
		Height = 80,
		OnChanged = function(Text)
			Choice.QuestTurnIn.SuccessText = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.LabeledInput("Failure Text:", {
		Value = Choice.QuestTurnIn.FailureText or "",
		PlaceholderText = "You haven't completed the quest yet...",
		Multiline = true,
		Height = 80,
		OnChanged = function(Text)
			Choice.QuestTurnIn.FailureText = Text ~= "" and Text or nil
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.Spacer(12).Parent = Base.Container

	local ResponseSection = NodeEditor.CreateSection(Base.Container, "Response Node", 2)

	if Choice.ResponseNode then
		Builder.LabeledInput("Continue Response:", {
			Value = Choice.ResponseNode.Text,
			PlaceholderText = "What would you like to do next?",
			Multiline = true,
			Height = 60,
			OnChanged = function(Text)
				Choice.ResponseNode.Text = Text
				OnRefresh()
			end
		}).Parent = ResponseSection

		local RemoveButton = Builder.Button({
			Text = "Remove Response",
			Type = "Danger",
			OnClick = function()
				Choice.ResponseNode = nil
				OnRefresh()
			end
		})
		RemoveButton.Size = UDim2.new(0, 150, 0, 32)
		RemoveButton.Parent = ResponseSection
	else
		local AddButton = Builder.Button({
			Text = "Add Response",
			Type = "Success",
			OnClick = function()
				Choice.ResponseNode = DialogTree.CreateNode("quest_continue", "Is there anything else?")
				OnRefresh()
			end
		})
		AddButton.Size = UDim2.new(0, 150, 0, 32)
		AddButton.Parent = ResponseSection
	end
end

return QuestTurnInEditor