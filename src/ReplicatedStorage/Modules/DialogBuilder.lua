--!strict
local DialogBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Modules = ReplicatedStorage:WaitForChild("Modules")
local QuestManager = require(Modules:WaitForChild("QuestManager"))

export type DialogNode = {
	Id: string,
	Text: string,
	Choices: {{Text: string, Response: DialogNode, Command: ((Player) -> ())?}}?,
	OpenGui: string?,
	GiveQuest: string?,
	TurnInQuest: string?
}

export type QuestTurnIn = {
	QuestId: string,
	Text: string,
	ResponseText: string,
	RewardText: string?
}

export type QuestOffer = {
	QuestId: string,
	ButtonText: string,
	IntroText: string,
	DetailText: string?,
	RewardText: string?,
	LocationText: string?,
	AcceptText: string?,
	DeclineText: string?
}

function DialogBuilder.HasActiveQuest(Player: Player, QuestId: string): boolean
	return QuestManager.HasActiveQuest(Player, QuestId)
end

function DialogBuilder.HasCompletedQuest(Player: Player, QuestId: string): boolean
	return QuestManager.HasCompletedQuest(Player, QuestId)
end

function DialogBuilder.CanTurnInQuest(Player: Player, QuestId: string): boolean
	local Quest = QuestManager.GetActiveQuest(Player, QuestId)
	if not Quest then return false end

	for _, Objective in ipairs(Quest.Objectives) do
		if not Objective.Completed then
			return false
		end
	end

	return true
end

function DialogBuilder.GetReputation(Player: Player, Faction: string): number
	return Player:GetAttribute("Reputation_" .. Faction) or 0
end

function DialogBuilder.HasReputation(Player: Player, Faction: string, MinAmount: number): boolean
	return DialogBuilder.GetReputation(Player, Faction) >= MinAmount
end

function DialogBuilder.CreateTurnInNode(TurnIn: QuestTurnIn): DialogNode
	return {
		Id = "turn_in_" .. TurnIn.QuestId,
		Text = TurnIn.Text,
		Choices = {
			{
				Text = TurnIn.Text,
				Response = {
					Id = "turn_in_complete_" .. TurnIn.QuestId,
					Text = TurnIn.ResponseText,
					TurnInQuest = TurnIn.QuestId
				}
			}
		}
	}
end

function DialogBuilder.CreateQuestOfferNode(QuestId: string, OfferText: string, QuestDescription: string): DialogNode
	return {
		Id = "offer_" .. QuestId,
		Text = OfferText,
		Choices = {
			{
				Text = "Tell me more",
				Response = {
					Id = "details_" .. QuestId,
					Text = QuestDescription,
					GiveQuest = QuestId
				}
			},
			{
				Text = "Not interested",
				Response = {
					Id = "decline_" .. QuestId,
					Text = "No problem. Come back if you change your mind."
				}
			}
		}
	}
end

-- Creates flexible quest offer with multiple info options
function DialogBuilder.BuildQuestOffer(Offer: QuestOffer): {Text: string, Response: DialogNode}
	local AcceptText = Offer.AcceptText or "Thank you! Good luck!"
	local DeclineText = Offer.DeclineText or "Come back if you change your mind."

	-- Helper to create accept/decline choices
	local function CreateAcceptDeclineChoices()
		return {
			{
				Text = "I'll do it",
				Response = {
					Id = "accept_" .. Offer.QuestId,
					Text = AcceptText
				},
				Command = function(Plr: Player)
					QuestManager.GiveQuest(Plr, Offer.QuestId)
				end
			},
			{
				Text = "Not interested",
				Response = {
					Id = "decline_" .. Offer.QuestId,
					Text = DeclineText
				}
			}
		}
	end

	-- Build the information choices (Tell me more, What's the reward, etc.)
	local InfoChoices = {}

	-- Always include "Tell me more" if DetailText is provided
	if Offer.DetailText then
		table.insert(InfoChoices, {
			Text = "Tell me more",
			Response = {
				Id = "details_" .. Offer.QuestId,
				Text = Offer.DetailText,
				Choices = CreateAcceptDeclineChoices()
			}
		})
	end

	-- Optional: "What's the reward?" option
	if Offer.RewardText then
		table.insert(InfoChoices, {
			Text = "What's in it for me?",
			Response = {
				Id = "reward_" .. Offer.QuestId,
				Text = Offer.RewardText,
				Choices = CreateAcceptDeclineChoices()
			}
		})
	end

	-- Optional: "Where do I go?" option
	if Offer.LocationText then
		table.insert(InfoChoices, {
			Text = "Where do I go?",
			Response = {
				Id = "location_" .. Offer.QuestId,
				Text = Offer.LocationText,
				Choices = CreateAcceptDeclineChoices()
			}
		})
	end

	-- If no detail text, allow immediate accept/decline
	if not Offer.DetailText then
		table.insert(InfoChoices, {
			Text = "Sure, I'll help",
			Response = {
				Id = "accept_immediate_" .. Offer.QuestId,
				Text = AcceptText
			},
			Command = function(Plr: Player)
				QuestManager.GiveQuest(Plr, Offer.QuestId)
			end
		})
	end

	-- Always allow immediate decline
	table.insert(InfoChoices, {
		Text = "Maybe later",
		Response = {
			Id = "decline_early_" .. Offer.QuestId,
			Text = DeclineText
		}
	})

	-- Return the full quest offer node
	return {
		Text = Offer.ButtonText,
		Response = {
			Id = "intro_" .. Offer.QuestId,
			Text = Offer.IntroText,
			Choices = InfoChoices
		}
	}
end

function DialogBuilder.BuildGreeting(_: string, Player: Player, Options: {
	DefaultGreeting: string,
	ActiveQuestGreetings: {{QuestId: string, Greeting: string}}?,
	CompletedQuestGreetings: {{QuestId: string, Greeting: string}}?,
	ReputationGreetings: {{Faction: string, MinRep: number, Greeting: string}}?
}): string
	if Options.ReputationGreetings then
		for _, RepGreeting in ipairs(Options.ReputationGreetings) do
			if DialogBuilder.HasReputation(Player, RepGreeting.Faction, RepGreeting.MinRep) then
				return RepGreeting.Greeting
			end
		end
	end

	if Options.ActiveQuestGreetings then
		for _, QuestGreeting in ipairs(Options.ActiveQuestGreetings) do
			if DialogBuilder.HasActiveQuest(Player, QuestGreeting.QuestId) then
				return QuestGreeting.Greeting
			end
		end
	end

	if Options.CompletedQuestGreetings then
		for _, QuestGreeting in ipairs(Options.CompletedQuestGreetings) do
			if DialogBuilder.HasCompletedQuest(Player, QuestGreeting.QuestId) then
				return QuestGreeting.Greeting
			end
		end
	end

	return Options.DefaultGreeting
end

function DialogBuilder.AddQuestTurnIns(Choices: {{Text: string, Response: DialogNode}}, Player: Player, TurnIns: {QuestTurnIn}): ()
	for _, TurnIn in ipairs(TurnIns) do
		if DialogBuilder.CanTurnInQuest(Player, TurnIn.QuestId) then
			table.insert(Choices, 1, {
				Text = "[QUEST] " .. TurnIn.Text,
				Response = {
					Id = "turn_in_complete_" .. TurnIn.QuestId,
					Text = TurnIn.ResponseText,
					TurnInQuest = TurnIn.QuestId
				}
			})
		end
	end
end

function DialogBuilder.AddQuestOffers(Choices: {{Text: string, Response: DialogNode}}, Player: Player, Offers: {{
	QuestId: string,
	OfferText: string,
	ButtonText: string,
	QuestDescription: string,
	RequireReputation: {Faction: string, MinAmount: number}?
}}): ()
	for _, Offer in ipairs(Offers) do
		local CanOffer = not DialogBuilder.HasActiveQuest(Player, Offer.QuestId)
			and not DialogBuilder.HasCompletedQuest(Player, Offer.QuestId)

		if CanOffer and Offer.RequireReputation then
			CanOffer = DialogBuilder.HasReputation(Player, Offer.RequireReputation.Faction, Offer.RequireReputation.MinAmount)
		end

		if CanOffer then
			table.insert(Choices, {
				Text = Offer.ButtonText,
				Response = DialogBuilder.CreateQuestOfferNode(Offer.QuestId, Offer.OfferText, Offer.QuestDescription)
			})
		end
	end
end

return DialogBuilder