--!strict
local NodeEditor = require(script.Parent.NodeEditor)
local Builder = require(script.Parent.Parent.Components.Builder)
local DialogTree = require(script.Parent.Parent.Core.DialogTree)

type DialogChoice = DialogTree.DialogChoice

local QuestEditor = {}

function QuestEditor.Render(Parent: ScrollingFrame, Choice: DialogChoice, OnRefresh: () -> ())
	local Base = NodeEditor.CreateBase(Parent, "Quest Editor")

	if not Choice.Quest then
		Choice.Quest = {
			QuestId = "",
			OfferText = "",
			Description = ""
		}
	end

	local BasicSection = NodeEditor.CreateSection(Base.Container, "Quest Offer", 1)

	Builder.LabeledInput("Button Text:", {
		Value = Choice.Text,
		PlaceholderText = "Enter choice text...",
		OnChanged = function(Text)
			Choice.Text = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.LabeledInput("Quest ID:", {
		Value = Choice.Quest.QuestId,
		PlaceholderText = "Enter quest ID...",
		OnChanged = function(Text)
			Choice.Quest.QuestId = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.LabeledInput("Offer Text:", {
		Value = Choice.Quest.OfferText,
		PlaceholderText = "I need your help with something...",
		Multiline = true,
		Height = 80,
		OnChanged = function(Text)
			Choice.Quest.OfferText = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.LabeledInput("Quest Description:", {
		Value = Choice.Quest.Description,
		PlaceholderText = "Collect 10 flowers from the forest...",
		Multiline = true,
		Height = 80,
		OnChanged = function(Text)
			Choice.Quest.Description = Text
			OnRefresh()
		end
	}).Parent = BasicSection

	Builder.Spacer(12).Parent = Base.Container

	local ResponseSection = NodeEditor.CreateSection(Base.Container, "Response Node", 2)

	if Choice.ResponseNode then
		Builder.LabeledInput("Accept Response:", {
			Value = Choice.ResponseNode.Text,
			PlaceholderText = "Thank you! Good luck!",
			Multiline = true,
			Height = 60,
			OnChanged = function(Text)
				Choice.ResponseNode.Text = Text
				OnRefresh()
			end
		}).Parent = ResponseSection
	else
		local AddButton = Builder.Button({
			Text = "Add Accept Response",
			Type = "Success",
			OnClick = function()
				Choice.ResponseNode = DialogTree.CreateNode("quest_accept", "Thank you for accepting!")
				OnRefresh()
			end
		})
		AddButton.Size = UDim2.new(0, 180, 0, 32)
		AddButton.Parent = ResponseSection
	end
end

return QuestEditor