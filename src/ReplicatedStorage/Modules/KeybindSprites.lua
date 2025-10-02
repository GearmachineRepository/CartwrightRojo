--!strict
local UserInputService = game:GetService("UserInputService")

local KeybindSprites = {}

-- Get PlatformManager
local PlatformManager = require(script.Parent:WaitForChild("PlatformManager"))

-- Sprite sheet configurations
local SPRITE_SIZE = 50 
local SPRITES_PER_ROW = 10

-- Asset IDs for sprite sheets
local SHEET_ASSETS = {
	PC = "rbxassetid://91135501257456",
	Controller = "rbxassetid://136901358312800",
	PlayStation = "rbxassetid://79766752552238",
}

-- Platform detection wrapper
type Platform = "PC" | "Controller" | "PlayStation"

local function GetCurrentPlatform(): Platform
	local platform = PlatformManager.GetPlatform()

	-- Need playstaton check
	
	if platform == "Controller" then
		return "Controller" 
	else
		return "PC"
	end
end

-- Keyboard mapping (based on your first image layout)
local KeyboardMap = {
	-- Row 1
	[Enum.KeyCode.A] = {0, 0},
	[Enum.KeyCode.B] = {1, 0},
	[Enum.KeyCode.C] = {2, 0},
	[Enum.KeyCode.D] = {3, 0},
	[Enum.KeyCode.E] = {4, 0},
	[Enum.KeyCode.F] = {5, 0},
	[Enum.KeyCode.G] = {6, 0},
	[Enum.KeyCode.H] = {7, 0},
	[Enum.KeyCode.I] = {8, 0},
	[Enum.KeyCode.J] = {9, 0},

	-- Row 2
	[Enum.KeyCode.K] = {0, 1},
	[Enum.KeyCode.L] = {1, 1},
	[Enum.KeyCode.M] = {2, 1},
	[Enum.KeyCode.N] = {3, 1},
	[Enum.KeyCode.O] = {4, 1},
	[Enum.KeyCode.P] = {5, 1},
	[Enum.KeyCode.Q] = {6, 1},
	[Enum.KeyCode.R] = {7, 1},
	[Enum.KeyCode.S] = {8, 1},
	[Enum.KeyCode.T] = {9, 1},

	-- Row 3
	[Enum.KeyCode.U] = {0, 2},
	[Enum.KeyCode.V] = {1, 2},
	[Enum.KeyCode.X] = {2, 2},
	[Enum.KeyCode.W] = {3, 2},
	[Enum.KeyCode.Y] = {4, 2},
	[Enum.KeyCode.Z] = {5, 2},
	[Enum.KeyCode.Zero] = {6, 2},
	[Enum.KeyCode.One] = {7, 2},
	[Enum.KeyCode.Two] = {8, 2},
	[Enum.KeyCode.Three] = {9, 2},

	-- Row 4
	[Enum.KeyCode.Four] = {0, 3},
	[Enum.KeyCode.Five] = {1, 3},
	[Enum.KeyCode.Six] = {2, 3},
	[Enum.KeyCode.Seven] = {3, 3},
	[Enum.KeyCode.Eight] = {4, 3},
	[Enum.KeyCode.Nine] = {5, 3},
	[Enum.KeyCode.F1] = {6, 3},
	[Enum.KeyCode.F2] = {7, 3},
	[Enum.KeyCode.F3] = {8, 3},
	[Enum.KeyCode.F4] = {9, 3},

	-- Row 5
	[Enum.KeyCode.F5] = {0, 4},
	[Enum.KeyCode.F6] = {1, 4},
	[Enum.KeyCode.F7] = {2, 4},
	[Enum.KeyCode.F8] = {3, 4},
	[Enum.KeyCode.F9] = {4, 4},
	[Enum.KeyCode.F10] = {5, 4},
	[Enum.KeyCode.F11] = {6, 4},
	[Enum.KeyCode.F12] = {7, 4},
	[Enum.KeyCode.Minus] = {8, 4},
	[Enum.KeyCode.Plus] = {9, 4},

	-- Row 6 (special keys)
	[Enum.KeyCode.LeftShift] = {1, 5},
	[Enum.KeyCode.RightShift] = {1, 5},
	[Enum.KeyCode.Semicolon] = {2, 5},
	[Enum.KeyCode.Slash] = {3, 5},
	[Enum.KeyCode.LeftBracket] = {4, 5},
	[Enum.KeyCode.RightBracket] = {5, 5},
	[Enum.KeyCode.Question] = {7, 5},
	[Enum.KeyCode.LeftAlt] = {8, 5},
	[Enum.KeyCode.RightAlt] = {8, 5},

	-- Row 8 (control keys)
	[Enum.KeyCode.Escape] = {0, 8},
	[Enum.KeyCode.LeftControl] = {1, 8},
	[Enum.KeyCode.RightControl] = {1, 8},
	[Enum.KeyCode.End] = {2, 8},
	[Enum.KeyCode.PageUp] = {3, 8},
	[Enum.KeyCode.PageDown] = {4, 8},
	[Enum.KeyCode.NumLock] = {5, 8},
	[Enum.KeyCode.Delete] = {6, 8},
	[Enum.KeyCode.Space] = {7, 8},
	[Enum.KeyCode.Return] = {4, 7},

	-- Row 9 (navigation)
	[Enum.KeyCode.Home] = {3, 9},
	[Enum.KeyCode.Tab] = {4, 9},
	[Enum.KeyCode.Insert] = {5, 9},
	[Enum.KeyCode.Backspace] = {6, 9},
}

-- Xbox/Controller mapping (based on your third image)
local ControllerMap = {
	-- Face buttons (row 1 & 2)
	[Enum.KeyCode.ButtonX] = {3, 0}, -- X (blue)
	[Enum.KeyCode.ButtonY] = {0, 0}, -- Y (yellow)
	[Enum.KeyCode.ButtonA] = {2, 0}, -- A (green)
	[Enum.KeyCode.ButtonB] = {1, 0}, -- B (red)

	-- Shoulders (row 3)
	[Enum.KeyCode.ButtonL1] = {0, 2}, -- LB
	[Enum.KeyCode.ButtonR1] = {1, 2}, -- RB
	[Enum.KeyCode.ButtonL2] = {2, 2}, -- LT
	[Enum.KeyCode.ButtonR2] = {3, 2}, -- RT

	-- D-Pad (row 4)
	[Enum.KeyCode.DPadUp] = {1, 3},
	[Enum.KeyCode.DPadDown] = {1, 3},
	[Enum.KeyCode.DPadLeft] = {0, 3},
	[Enum.KeyCode.DPadRight] = {2, 3},

	-- Sticks (row 5+)
	[Enum.KeyCode.ButtonL3] = {1, 4}, -- L stick pressed
	[Enum.KeyCode.ButtonR3] = {1, 6}, -- R stick pressed
	[Enum.KeyCode.Thumbstick1] = {0, 8}, -- Left stick
	[Enum.KeyCode.Thumbstick2] = {1, 8}, -- Right stick

	-- Special buttons (row 10)
	[Enum.KeyCode.ButtonSelect] = {0, 10}, -- Menu
	[Enum.KeyCode.ButtonStart] = {1, 10}, -- View
}

-- PlayStation mapping (based on your second image)
local PlayStationMap = {
	-- Face buttons (row 1 & 2)
	[Enum.KeyCode.ButtonX] = {2, 0}, -- X (Cross on top position)
	[Enum.KeyCode.ButtonY] = {0, 0}, -- Triangle
	[Enum.KeyCode.ButtonA] = {3, 0}, -- Cross (bottom)
	[Enum.KeyCode.ButtonB] = {1, 0}, -- Circle

	-- Shoulders (row 3)
	[Enum.KeyCode.ButtonL1] = {0, 2},
	[Enum.KeyCode.ButtonR1] = {1, 2},
	[Enum.KeyCode.ButtonL2] = {2, 2},
	[Enum.KeyCode.ButtonR2] = {3, 2},

	-- Sticks (row 4+)
	[Enum.KeyCode.ButtonL3] = {1, 3}, -- L3 pressed
	[Enum.KeyCode.ButtonR3] = {1, 7}, -- R3 pressed
	[Enum.KeyCode.Thumbstick1] = {0, 9}, -- Left stick
	[Enum.KeyCode.Thumbstick2] = {1, 9}, -- Right stick

	-- D-Pad
	[Enum.KeyCode.DPadUp] = {1, 13},
	[Enum.KeyCode.DPadDown] = {1, 13},
	[Enum.KeyCode.DPadLeft] = {0, 13},
	[Enum.KeyCode.DPadRight] = {2, 13},

	-- Special buttons
	[Enum.KeyCode.ButtonSelect] = {0, 17}, -- Options
	[Enum.KeyCode.ButtonStart] = {1, 17}, -- Share
}

-- Get the appropriate map for current platform
local function GetPlatformMap(platform: Platform)
	if platform == "PlayStation" then
		return PlayStationMap
	elseif platform == "Controller" then
		return ControllerMap
	else
		return KeyboardMap
	end
end

-- Convert grid position to ImageRectOffset
local function GridToImageRect(x: number, y: number, spriteSize: number): Vector2
	return Vector2.new(x * spriteSize, y * spriteSize)
end

-- Get asset ID for platform
local function GetSheetAsset(platform: Platform): string
	if platform == "PlayStation" then
		return SHEET_ASSETS.PlayStation
	elseif platform == "Controller" then
		return SHEET_ASSETS.Controller
	else
		return SHEET_ASSETS.PC
	end
end

-- Main function: Get sprite info for a keybind
function KeybindSprites.GetSpriteForKeybind(keybind: Enum.KeyCode | Enum.UserInputType, forcePlatform: Platform?): {ImageRectOffset: Vector2, ImageRectSize: Vector2, AssetId: string}?
	local platform = forcePlatform or GetCurrentPlatform()
	local map = GetPlatformMap(platform)

	local gridPos = map[keybind]
	if not gridPos then
		warn("[KeybindSprites] No sprite found for keybind:", keybind, "on platform:", platform)
		return nil
	end

	local imageRectOffset = GridToImageRect(gridPos[1], gridPos[2], SPRITE_SIZE)

	return {
		ImageRectOffset = imageRectOffset,
		ImageRectSize = Vector2.new(SPRITE_SIZE, SPRITE_SIZE),
		AssetId = GetSheetAsset(platform)
	}
end

-- Helper: Create an ImageLabel with the keybind sprite
function KeybindSprites.CreateKeybindIcon(keybind: Enum.KeyCode | Enum.UserInputType, parent: Instance?, size: UDim2?): ImageLabel?
	local spriteInfo = KeybindSprites.GetSpriteForKeybind(keybind)
	if not spriteInfo then return nil end

	local icon = Instance.new("ImageLabel")
	icon.Name = "KeybindIcon"
	icon.Size = size or UDim2.new(0, 50, 0, 50)
	icon.BackgroundTransparency = 1
	icon.Image = spriteInfo.AssetId
	icon.ImageRectOffset = spriteInfo.ImageRectOffset
	icon.ImageRectSize = spriteInfo.ImageRectSize
	icon.ScaleType = Enum.ScaleType.Fit

	if parent then
		icon.Parent = parent
	end

	return icon
end

-- Helper: Update existing ImageLabel with new keybind (reactive to platform changes)
function KeybindSprites.UpdateKeybindIcon(imageLabel: ImageLabel, keybind: Enum.KeyCode | Enum.UserInputType)
	local spriteInfo = KeybindSprites.GetSpriteForKeybind(keybind)
	if not spriteInfo then return end

	imageLabel.Image = spriteInfo.AssetId
	imageLabel.ImageRectOffset = spriteInfo.ImageRectOffset
	imageLabel.ImageRectSize = spriteInfo.ImageRectSize
end

-- Helper: Get current platform name
function KeybindSprites.GetPlatform(): Platform
	return GetCurrentPlatform()
end

-- Helper: Make an icon reactive to platform changes
function KeybindSprites.MakeIconReactive(imageLabel: ImageLabel, keybind: Enum.KeyCode | Enum.UserInputType): () -> ()
	-- Initial update
	KeybindSprites.UpdateKeybindIcon(imageLabel, keybind)

	-- Listen for platform changes
	local function onPlatformChanged(newPlatform: string)
		KeybindSprites.UpdateKeybindIcon(imageLabel, keybind)
	end

	PlatformManager.OnPlatformChanged(onPlatformChanged)

	-- Return cleanup function
	return function()
		PlatformManager.RemovePlatformChangeCallback(onPlatformChanged)
	end
end


return KeybindSprites