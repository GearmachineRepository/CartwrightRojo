--!strict

local DialogHelpers = {}

local function CreateSimpleResponse(Id: string, Text: string)
	return {
		Id = Id,
		Text = Text
	}
end

function DialogHelpers.BuildConversationChain(Options: {
	ButtonText: string,
	Chain: {{Player: string, NPC: string}},
	FinalText: string?,
	Command: ((Player) -> ())?
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

	local Choice = {
		Text = Options.ButtonText,
		Response = {
			Id = "conversation_start",
			Text = Options.Chain[1].NPC,
			Choices = #Options.Chain > 1 and {BuildChainRecursive(2)} or nil
		}
	}

	if Options.Command then
		Choice.Command = Options.Command
	end

	return Choice
end

function DialogHelpers.BuildShopDialog(Options: {
	ButtonText: string,
	ShopName: string?,
	IntroText: string,
	GuiName: string,
	Command: ((Player) -> ())?
}): {Text: string, Response: any}

	local Choice = {
		Text = Options.ButtonText,
		Response = {
			Id = "shop_" .. (Options.ShopName or "default"),
			Text = Options.IntroText,
			OpenGui = Options.GuiName
		}
	}

	if Options.Command then
		Choice.Command = Options.Command
	end

	return Choice
end

function DialogHelpers.BuildInfoBranch(Options: {
	ButtonText: string,
	IntroText: string,
	Questions: {{Question: string, Answer: string, Command: ((Player) -> ())?}},
	ExitText: string?,
	Command: ((Player) -> ())?
}): {Text: string, Response: any}

	local QuestionChoices = {}

	for Index, QA in ipairs(Options.Questions) do
		local QuestionChoice = {
			Text = QA.Question,
			Response = CreateSimpleResponse("info_" .. tostring(Index), QA.Answer)
		}

		if QA.Command then
			QuestionChoice.Command = QA.Command
		end

		table.insert(QuestionChoices, QuestionChoice)
	end

	if Options.ExitText then
		table.insert(QuestionChoices, {
			Text = Options.ExitText,
			Response = CreateSimpleResponse("info_exit", "Anytime!")
		})
	end

	local Choice = {
		Text = Options.ButtonText,
		Response = {
			Id = "info_branch",
			Text = Options.IntroText,
			Choices = QuestionChoices
		}
	}

	if Options.Command then
		Choice.Command = Options.Command
	end

	return Choice
end

function DialogHelpers.BuildGiveItem(Options: {
	ButtonText: string,
	AskText: string?,
	ResponseText: string,
	ItemName: string,
	ItemLocation: Instance?,
	Amount: number?,
	Command: ((Player) -> ())?
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

			if Options.Command then
				Options.Command(Player)
			end
		end
	}
end

function DialogHelpers.BuildFlagCheck(Options: {
	FlagName: string,
	ButtonText: string,
	ResponseText: string,
	AlternativeText: string?,
	ShowIfTrue: boolean?,
	Command: ((Player) -> ())?
}): (Player: Player) -> {Text: string, Response: any}?

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

		local Choice = {
			Text = Options.ButtonText,
			Response = CreateSimpleResponse("flag_check", Options.ResponseText)
		}

		if Options.Command then
			Choice.Command = Options.Command
		end

		return Choice
	end
end

function DialogHelpers.BuildMultiChoiceQuiz(Options: {
	ButtonText: string,
	Question: string,
	Choices: {{Text: string, Correct: boolean, Response: string}},
	OnSuccess: ((Player) -> ())?,
	OnFailure: ((Player) -> ())?,
	Command: ((Player) -> ())?
}): {Text: string, Response: any}

	local QuizChoices = {}

	for Index, Choice in ipairs(Options.Choices) do
		table.insert(QuizChoices, {
			Text = Choice.Text,
			Response = CreateSimpleResponse("quiz_" .. tostring(Index), Choice.Response),
			Command = Choice.Correct and Options.OnSuccess or Options.OnFailure
		})
	end

	local QuizChoice = {
		Text = Options.ButtonText,
		Response = {
			Id = "quiz_question",
			Text = Options.Question,
			Choices = QuizChoices
		}
	}

	if Options.Command then
		QuizChoice.Command = Options.Command
	end

	return QuizChoice
end

function DialogHelpers.BuildTradeOffer(Options: {
	ButtonText: string,
	RequestText: string,
	RequiredItem: string,
	RequiredAmount: number,
	GiveItem: string,
	GiveAmount: number?,
	SuccessText: string,
	FailureText: string,
	ItemLocation: Instance?,
	Command: ((Player) -> ())?
}): {Text: string, Response: any}

	local ItemLoc = Options.ItemLocation or game.ServerStorage.Items
	local GiveAmount = Options.GiveAmount or 1

	local Choice = {
		Text = Options.ButtonText,
		Response = {
			Id = "trade_offer",
			Text = Options.RequestText,
			Choices = {
				{
					Text = "I have them",
					Response = CreateSimpleResponse("trade_attempt", ""),
					Command = function(Player: Player)
						local HasItems = 0
						for _, Item in pairs(Player.Backpack:GetChildren()) do
							if Item.Name == Options.RequiredItem then
								HasItems = HasItems + 1
							end
						end

						if HasItems >= Options.RequiredAmount then
							local Removed = 0
							for _, Item in pairs(Player.Backpack:GetChildren()) do
								if Item.Name == Options.RequiredItem and Removed < Options.RequiredAmount then
									Item:Destroy()
									Removed = Removed + 1
								end
							end

							for _ = 1, GiveAmount do
								local GiveItemInstance = ItemLoc:FindFirstChild(Options.GiveItem)
								if GiveItemInstance then
									GiveItemInstance:Clone().Parent = Player.Backpack
								end
							end

							if Options.Command then
								Options.Command(Player)
							end
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

	return Choice
end

function DialogHelpers.BuildReputationGate(Options: {
	Faction: string,
	MinRep: number,
	ButtonText: string,
	LockedText: string,
	UnlockedContent: {Text: string, Response: any},
	Command: ((Player) -> ())?
}): (Player: Player) -> {Text: string, Response: any}

	return function(Player: Player)
		local Rep = Player:GetAttribute("Reputation_" .. Options.Faction) or 0

		if Rep < Options.MinRep then
			return {
				Text = Options.ButtonText,
				Response = CreateSimpleResponse("rep_locked", Options.LockedText)
			}
		end

		local Choice = {
			Text = Options.ButtonText,
			Response = Options.UnlockedContent.Response
		}

		if Options.Command then
			Choice.Command = Options.Command
		end

		return Choice
	end
end

function DialogHelpers.BuildRandomDialog(Options: {
	ButtonText: string,
	Responses: {string},
	FollowUp: {{Text: string, Response: any}}?,
	Command: ((Player) -> ())?
}): (Player: Player) -> {Text: string, Response: any}

	return function(_: Player)
		local RandomResponse = Options.Responses[math.random(1, #Options.Responses)]

		local Choice = {
			Text = Options.ButtonText,
			Response = {
				Id = "random_dialog",
				Text = RandomResponse,
				Choices = Options.FollowUp
			}
		}

		if Options.Command then
			Choice.Command = Options.Command
		end

		return Choice
	end
end

function DialogHelpers.BuildSimpleGreeting(Options: {
	Greetings: {string},
	Farewells: {string}?,
	Command: ((Player) -> ())?
}): any

	local Greeting = Options.Greetings[math.random(1, #Options.Greetings)]
	local Farewell = "Goodbye!"

	if Options.Farewells then
		Farewell = Options.Farewells[math.random(1, #Options.Farewells)]
	end

	local GoodbyeChoice = {
		Text = "Goodbye",
		Response = CreateSimpleResponse("farewell", Farewell)
	}

	if Options.Command then
		GoodbyeChoice.Command = Options.Command
	end

	return {
		Id = "start",
		Text = Greeting,
		Choices = {GoodbyeChoice}
	}
end

function DialogHelpers.GetConditionalGreeting(Conditions: {{any}}, DefaultGreeting: string): string
	for _, Condition in ipairs(Conditions) do
		if Condition[1] then
			return Condition[2]
		end
	end
	return DefaultGreeting
end

function DialogHelpers.CreateSimpleChoice(Text: string, ResponseText: string, Id: string?, Command: ((Player) -> ())?): {Text: string, Response: any}
	local Choice = {
		Text = Text,
		Response = CreateSimpleResponse(Id or "simple_choice", ResponseText)
	}

	if Command then
		Choice.Command = Command
	end

	return Choice
end

function DialogHelpers.CreateBranchingChoice(
	ButtonText: string,
	InitialResponse: string,
	SubChoices: {{Text: string, Response: any}},
	Id: string?,
	Command: ((Player) -> ())?
): {Text: string, Response: any}
	local Choice = {
		Text = ButtonText,
		Response = {
			Id = Id or "branching_choice",
			Text = InitialResponse,
			Choices = SubChoices
		}
	}

	if Command then
		Choice.Command = Command
	end

	return Choice
end

function DialogHelpers.CreateNestedChoice(
	ButtonText: string,
	ResponseText: string,
	NestedChoices: {{Text: string, Response: any}},
	Id: string?,
	Command: ((Player) -> ())?
): {Text: string, Response: any}
	local Choice = {
		Text = ButtonText,
		Response = {
			Id = Id or "nested_choice",
			Text = ResponseText,
			Choices = NestedChoices
		}
	}

	if Command then
		Choice.Command = Command
	end

	return Choice
end

function DialogHelpers.CreateDialogStart(GreetingText: string, Choices: {{Text: string, Response: any}}): {Id: string, Text: string, Choices: any}
	return {
		Id = "start",
		Text = GreetingText,
		Choices = Choices
	}
end

DialogHelpers.Advanced = require(script.Parent:WaitForChild("AdvancedDialogHelper"))

return DialogHelpers