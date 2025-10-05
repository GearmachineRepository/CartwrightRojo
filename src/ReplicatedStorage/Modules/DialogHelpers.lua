--!strict
--[[
	DIALOG HELPERS LIBRARY

	A collection of helper functions to make dialog creation easier.
	These tools handle common dialog patterns so you don't have to write nested tables.

	Usage:
	local DialogHelpers = require(Modules:WaitForChild("DialogHelpers"))
	table.insert(Choices, DialogHelpers.BuildShopDialog({...}))
]]

local DialogHelpers = {}

--local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local Modules = ReplicatedStorage:WaitForChild("Modules")
-- local QuestManager = require(Modules:WaitForChild("QuestManager"))
-- local DialogConditions = require(Modules:WaitForChild("DialogConditions"))

-- Helper to create simple response nodes
local function CreateSimpleResponse(Id: string, Text: string)
	return {
		Id = Id,
		Text = Text
	}
end

-- ═══════════════════════════════════════════════════════════
-- 1. BuildConversationChain
-- Creates a linear back-and-forth conversation
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildConversationChain(Options: {
	ButtonText: string,
	Chain: {{Player: string, NPC: string}},
	FinalText: string?
}): {Text: string, Response: any}

	local function BuildChainRecursive(Index: number)
		if Index > #Options.Chain then
			return nil
		end

		local CurrentLink = Options.Chain[Index]
		local NextChain = BuildChainRecursive(Index + 1)

		return {
			Text = CurrentLink.Player,
			Response = {
				Id = "chain_" .. tostring(Index),
				Text = CurrentLink.NPC,
				Choices = NextChain and {NextChain} or nil
			}
		}
	end

	local FirstChoice = BuildChainRecursive(1)

	if Options.FinalText and FirstChoice then
		-- Add a final "Goodbye" at the end
		local function AddFinalNode(Node)
			if Node.Response.Choices then
				AddFinalNode(Node.Response.Choices[1])
			else
				Node.Response.Choices = {
					{
						Text = Options.FinalText or "Thanks",
						Response = CreateSimpleResponse("chain_end", "Anytime!")
					}
				}
			end
		end
		AddFinalNode(FirstChoice)
	end

	return {
		Text = Options.ButtonText,
		Response = {
			Id = "conversation_start",
			Text = Options.Chain[1].NPC,
			Choices = #Options.Chain > 1 and {BuildChainRecursive(2)} or nil
		}
	}
end

-- ═══════════════════════════════════════════════════════════
-- 2. BuildShopDialog
-- Standardized shop interaction
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildShopDialog(Options: {
	ButtonText: string,
	ShopName: string?,
	IntroText: string,
	GuiName: string
}): {Text: string, Response: any}

	return {
		Text = Options.ButtonText,
		Response = {
			Id = "shop_" .. (Options.ShopName or "default"),
			Text = Options.IntroText,
			OpenGui = Options.GuiName
		}
	}
end

-- ═══════════════════════════════════════════════════════════
-- 3. BuildInfoBranch
-- Multiple questions the player can ask
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildInfoBranch(Options: {
	ButtonText: string,
	IntroText: string,
	Questions: {{Question: string, Answer: string}},
	ExitText: string?
}): {Text: string, Response: any}

	local QuestionChoices = {}

	for Index, QA in ipairs(Options.Questions) do
		table.insert(QuestionChoices, {
			Text = QA.Question,
			Response = CreateSimpleResponse("info_" .. tostring(Index), QA.Answer)
		})
	end

	if Options.ExitText then
		table.insert(QuestionChoices, {
			Text = Options.ExitText,
			Response = CreateSimpleResponse("info_exit", "Anytime!")
		})
	end

	return {
		Text = Options.ButtonText,
		Response = {
			Id = "info_branch",
			Text = Options.IntroText,
			Choices = QuestionChoices
		}
	}
end

-- ═══════════════════════════════════════════════════════════
-- 4. BuildGiveItem
-- Simple item giving
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildGiveItem(Options: {
	ButtonText: string,
	AskText: string?,
	ResponseText: string,
	ItemName: string,
	ItemLocation: Instance?,
	Amount: number?
}): {Text: string, Response: any}

	local ItemLoc = Options.ItemLocation or game.ServerStorage.Items
	local ItemAmount = Options.Amount or 1

	return {
		Text = Options.ButtonText,
		Response = {
			Id = "give_item_" .. Options.ItemName,
			Text = Options.ResponseText
		},
		Command = function(Player: Player)
			for _ = 1, ItemAmount do
				local Item = ItemLoc:FindFirstChild(Options.ItemName)
				if Item then
					Item:Clone().Parent = Player.Backpack
				else
					warn("[DialogHelpers] Item not found: " .. Options.ItemName)
				end
			end
		end
	}
end

-- ═══════════════════════════════════════════════════════════
-- 5. BuildFlagCheck
-- Show dialog only if flag is set
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildFlagCheck(Options: {
	FlagName: string,
	ButtonText: string,
	ResponseText: string,
	AlternativeText: string?,
	ShowIfTrue: boolean?
}): {Text: string, Response: any}?

	-- This returns a function that the dialog can call to conditionally add
	return function(Player: Player)
		local HasFlag = Player:GetAttribute("DialogFlag_" .. Options.FlagName) == true
		local ShouldShow = Options.ShowIfTrue == false and not HasFlag or HasFlag

		if not ShouldShow then
			if Options.AlternativeText then
				return {
					Text = Options.ButtonText,
					Response = CreateSimpleResponse("flag_check_alt", Options.AlternativeText)
				}
			end
			return nil
		end

		return {
			Text = Options.ButtonText,
			Response = CreateSimpleResponse("flag_check", Options.ResponseText)
		}
	end
end

-- ═══════════════════════════════════════════════════════════
-- 6. BuildMultiChoiceQuiz
-- For riddles, passwords, knowledge checks
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildMultiChoiceQuiz(Options: {
	ButtonText: string,
	Question: string,
	Choices: {{Text: string, Correct: boolean, Response: string}},
	OnSuccess: ((Player) -> ())?,
	OnFailure: ((Player) -> ())?
}): {Text: string, Response: any}

	local QuizChoices = {}

	for Index, Choice in ipairs(Options.Choices) do
		table.insert(QuizChoices, {
			Text = Choice.Text,
			Response = CreateSimpleResponse("quiz_" .. tostring(Index), Choice.Response),
			Command = Choice.Correct and Options.OnSuccess or Options.OnFailure
		})
	end

	return {
		Text = Options.ButtonText,
		Response = {
			Id = "quiz_question",
			Text = Options.Question,
			Choices = QuizChoices
		}
	}
end

-- ═══════════════════════════════════════════════════════════
-- 7. BuildTradeOffer
-- Simple item-for-item trading
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildTradeOffer(Options: {
	ButtonText: string,
	RequestText: string,
	RequiredItem: string,
	RequiredAmount: number,
	GiveItem: string,
	GiveAmount: number?,
	SuccessText: string,
	FailureText: string,
	ItemLocation: Instance?
}): {Text: string, Response: any}

	local ItemLoc = Options.ItemLocation or game.ServerStorage.Items
	local GiveAmt = Options.GiveAmount or 1

	return {
		Text = Options.ButtonText,
		Response = {
			Id = "trade_check",
			Text = Options.RequestText,
			Choices = {
				{
					Text = "I have them",
					Response = CreateSimpleResponse("trade_attempt", ""),
					Command = function(Player: Player)
						local Backpack = Player:FindFirstChild("Backpack")
						local Character = Player.Character
						local Count = 0

						if Backpack then
							for _, Item in ipairs(Backpack:GetChildren()) do
								if Item.Name == Options.RequiredItem then
									Count = Count + 1
								end
							end
						end

						if Character then
							for _, Item in ipairs(Character:GetChildren()) do
								if Item.Name == Options.RequiredItem then
									Count = Count + 1
								end
							end
						end

						if Count >= Options.RequiredAmount then
							-- Remove required items
							local Removed = 0
							while Removed < Options.RequiredAmount do
								local Item = Backpack and Backpack:FindFirstChild(Options.RequiredItem)
								if not Item and Character then
									Item = Character:FindFirstChild(Options.RequiredItem)
								end
								if Item then
									Item:Destroy()
									Removed = Removed + 1
								else
									break
								end
							end

							-- Give reward items
							for _ = 1, GiveAmt do
								local RewardItem = ItemLoc:FindFirstChild(Options.GiveItem)
								if RewardItem then
									RewardItem:Clone().Parent = Player.Backpack
								end
							end

							-- Show success message via chat or notification
							print("[Trade] " .. Player.Name .. " traded successfully")
						end
					end
				},
				{
					Text = "Not yet",
					Response = CreateSimpleResponse("trade_decline", Options.FailureText)
				}
			}
		}
	}
end

-- ═══════════════════════════════════════════════════════════
-- 8. BuildReputationGate
-- Content locked behind reputation
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildReputationGate(Options: {
	Faction: string,
	MinRep: number,
	ButtonText: string,
	LockedText: string,
	UnlockedContent: {Text: string, Response: any}
}): {Text: string, Response: any}

	return function(Player: Player)
		local Rep = Player:GetAttribute("Reputation_" .. Options.Faction) or 0

		if Rep < Options.MinRep then
			return {
				Text = Options.ButtonText,
				Response = CreateSimpleResponse("rep_locked", Options.LockedText)
			}
		end

		return {
			Text = Options.ButtonText,
			Response = Options.UnlockedContent.Response
		}
	end
end

-- ═══════════════════════════════════════════════════════════
-- 9. BuildRandomDialog
-- Randomly vary responses for ambient NPCs
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildRandomDialog(Options: {
	ButtonText: string,
	Responses: {string},
	FollowUp: {{Text: string, Response: any}}?
}): {Text: string, Response: any}

	return function(_: Player)
		local RandomResponse = Options.Responses[math.random(1, #Options.Responses)]

		return {
			Text = Options.ButtonText,
			Response = {
				Id = "random_dialog",
				Text = RandomResponse,
				Choices = Options.FollowUp
			}
		}
	end
end

-- ═══════════════════════════════════════════════════════════
-- 10. BuildSimpleGreeting
-- Quick ambient NPC with random greetings
-- ═══════════════════════════════════════════════════════════
function DialogHelpers.BuildSimpleGreeting(Options: {
	Greetings: {string},
	Farewells: {string}?
}): ()

	local Greeting = Options.Greetings[math.random(1, #Options.Greetings)]
	local Farewell = "Goodbye!"

	if Options.Farewells then
		Farewell = Options.Farewells[math.random(1, #Options.Farewells)]
	end

	return {
		Id = "start",
		Text = Greeting,
		Choices = {
			{
				Text = "Goodbye",
				Response = CreateSimpleResponse("farewell", Farewell)
			}
		}
	}
end

return DialogHelpers