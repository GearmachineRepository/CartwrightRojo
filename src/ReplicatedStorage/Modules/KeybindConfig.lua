--!strict

local KeybindConfig = {}

KeybindConfig.Keybinds = {
	PC = {
		Interact = Enum.KeyCode.E,
		Drag = Enum.UserInputType.MouseButton1,
		DistanceModifier = Enum.KeyCode.Q,
		Cancel = Enum.KeyCode.Escape
	},
	Controller = {
		Interact = Enum.KeyCode.ButtonX,
		Drag = Enum.KeyCode.ButtonL2,
		DistanceModifier = Enum.KeyCode.ButtonR2,
		Cancel = Enum.KeyCode.ButtonB,
		Drop = Enum.KeyCode.ButtonY
	},
	Mobile = {
		Interact = "TouchTap",
		Drag = "TouchHold",
		Drop = "TouchHold",
		Cancel = "TouchDoubleTap"
	}
}

function KeybindConfig.GetKeybind(Platform: string, Action: string)
	local PlatformKeybinds = KeybindConfig.Keybinds[Platform]
	if PlatformKeybinds then
		return PlatformKeybinds[Action]
	end
	return nil
end

function KeybindConfig.GetDisplayText(Platform: string, Action: string): string
	local Keybind = KeybindConfig.GetKeybind(Platform, Action)
	if not Keybind then 
		return Action 
	end

	if type(Keybind) == "string" then
		local MobileDisplays = {
			["TouchTap"] = "Tap",
			["TouchHold"] = "Hold", 
			["TouchDoubleTap"] = "Double Tap"
		}
		return MobileDisplays[Keybind] or Keybind
	end

	local EnumName = Keybind.Name

	local CustomDisplays = {
		["MouseButton1"] = "Left Click",
		["MouseButton2"] = "Right Click",
		["MouseButton3"] = "Middle Click",
		["Return"] = "Enter",
		["LeftShift"] = "Shift",
		["RightShift"] = "Shift",
		["ButtonX"] = "X",
		["ButtonY"] = "Y",
		["ButtonA"] = "A",
		["ButtonB"] = "B",
		["ButtonR1"] = "RB",
		["ButtonR2"] = "RT",
		["ButtonL1"] = "LB",
		["ButtonL2"] = "LT"
	}

	return CustomDisplays[EnumName] or EnumName
end

return KeybindConfig