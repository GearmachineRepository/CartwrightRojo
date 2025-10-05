--[[
	═══════════════════════════════════════════════════════════════
	VISUAL DIALOG STRUCTURE GUIDE
	═══════════════════════════════════════════════════════════════

	This shows you how dialog flows. Each level of indentation = deeper in conversation


	SIMPLE EXAMPLE:
	================

	Player talks to NPC
	    ↓
	NPC: "Hello!"
	    ↓
	Player sees choices:
	    → "How are you?"
	    → "Goodbye"


	If player clicks "How are you?":
	    ↓
	NPC: "I'm doing well!"
	    ↓
	Conversation ends


	NESTED EXAMPLE (conversation goes deeper):
	==========================================

	Player talks to NPC
	    ↓
	NPC: "Hello!"
	    ↓
	Player sees choices:
	    → "Tell me about yourself"
	    → "Goodbye"


	If player clicks "Tell me about yourself":
	    ↓
	NPC: "I've lived here my whole life. What would you like to know?"
	    ↓
	Player sees NEW choices:
	        → "What do you do?"
	        → "Do you like living here?"


	If player clicks "What do you do?":
	    ↓
	NPC: "I'm a farmer!"
	    ↓
	Conversation ends


	HOW THIS LOOKS IN CODE:
	========================
]]

local VISUAL_EXAMPLE = {
	-- LEVEL 1 - First choice player sees
	{
		Text = "Tell me about yourself",  -- What the button says
		Response = "I've lived here my whole life. What would you like to know?",  -- What NPC says

		-- LEVEL 2 - Choices that appear AFTER the response above
		Choices = {
			{
				Text = "What do you do?",
				Response = "I'm a farmer!"
				-- No Choices here = conversation ends
			},
			{
				Text = "Do you like living here?",
				Response = "Oh yes, it's peaceful!",

				-- LEVEL 3 - You can go even deeper!
				Choices = {
					{
						Text = "Why is it peaceful?",
						Response = "Not many visitors around here."
					}
				}
			}
		}
	}
}

--[[
	BROTHERS QUEST EXAMPLE:
	=======================

	Player talks to Brother Two
	    ↓
	Brother Two: "Hello stranger!"
	    ↓
	Player sees:
	    → "How are you doing?"        ← Click this
	    → "Goodbye"


	Player clicked "How are you doing?"
	    ↓
	Brother Two: "I'm doing well! My brother worries too much."
	    ↓
	Player sees:
	        → "He'll be relieved to hear that"    ← Click this


	Player clicked "He'll be relieved to hear that"
	    ↓
	Brother Two: "Could you take this letter back to him?"
	    ↓
	Player sees:
	            → "Of course, I'd be happy to"     ← Click this
	            → "I'm kind of busy right now"


	Player clicked "Of course, I'd be happy to"
	    ↓
	Brother Two: "Thank you!"
	    ↓
	[GAME GIVES LETTER TO PLAYER]    ← This is an "Action"
	    ↓
	Conversation ends


	HOW THE BROTHERS DIALOG LOOKS IN CODE:
	=======================================
]]

local BROTHERS_EXAMPLE = {
	{
		Text = "How are you doing?",
		Response = "I'm doing well! My brother worries too much.",
		Choices = {
			{
				Text = "He'll be relieved to hear that",
				Response = "Could you take this letter back to him?",
				Choices = {
					{
						Text = "Of course, I'd be happy to",
						Response = "Thank you!",
						Action = function(Player)
							-- Give letter to player
							-- Start quest
						end
					},
					{
						Text = "I'm kind of busy right now",
						Response = "No worries, maybe next time."
					}
				}
			}
		}
	}
}

--[[
	KEY CONCEPTS:
	=============

	1. INDENTATION = DEPTH
	   More indented = deeper in conversation

	2. "Choices" INSIDE "Choices" = NESTED CONVERSATION
	   Each level of Choices = one more question/answer

	3. NO "Choices" = CONVERSATION ENDS
	   When there's no Choices table, dialog finishes

	4. "Action" = SOMETHING HAPPENS
	   Use Action to give items, set flags, update quests


	COMMON MISTAKES:
	================

	❌ WRONG - Missing comma between choices:
	{
		Text = "Hello"
		Response = "Hi"
	}
	{
		Text = "Goodbye"
		Response = "Bye"
	}

	✓ CORRECT - Comma after each choice:
	{
		Text = "Hello",
		Response = "Hi"
	},
	{
		Text = "Goodbye",
		Response = "Bye"
	}


	❌ WRONG - Choices not in a table:
	Choices = {
		Text = "Option 1",
		Response = "Response 1"
	}

	✓ CORRECT - Choices is an array:
	Choices = {
		{
			Text = "Option 1",
			Response = "Response 1"
		}
	}


	QUICK REFERENCE:
	================

	Text      = What the button says
	Response  = What the NPC says back
	Choices   = More options (optional)
	Action    = Code that runs (optional)
	ShowIf    = Condition to show (optional)
]]

return {}