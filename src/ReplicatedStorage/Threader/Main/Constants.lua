--!strict

local Constants = {}

Constants.SKILLS = {
	"Perception",
	"Empathy",
	"Logic",
	"Authority",
	"Rhetoric",
	"Composure",
	"Endurance",
	"Streetwise"
}

Constants.CONDITION_TYPES = {
	"HasQuest",
	"CompletedQuest",
	"CanTurnInQuest",
	"HasReputation",
	"HasAttribute",
	"HasItem",
	"Level",
	"HasSkill",
	"DialogFlag",
}

Constants.COLORS = {
	Background = Color3.fromRGB(20, 23, 28),
	BackgroundLight = Color3.fromRGB(26, 29, 35),
	BackgroundDark = Color3.fromRGB(15, 18, 23),
	Panel = Color3.fromRGB(35, 39, 47),
	PanelHover = Color3.fromRGB(45, 49, 57),
	Card = Color3.fromRGB(30, 34, 42),

	Primary = Color3.fromRGB(70, 140, 200),       -- was 88, 166, 255
	PrimaryHover = Color3.fromRGB(85, 160, 215),  -- was 108, 186, 255
	PrimaryDark = Color3.fromRGB(60, 120, 180),   -- was 68, 146, 235

	Success = Color3.fromRGB(60, 150, 100),       -- was 72, 187, 120
	SuccessHover = Color3.fromRGB(75, 170, 115),  -- was 92, 207, 140
	SuccessDark = Color3.fromRGB(50, 130, 85),    -- was 52, 167, 100

	Danger = Color3.fromRGB(200, 70, 65),         -- was 239, 83, 80
	DangerHover = Color3.fromRGB(220, 90, 85),    -- was 255, 103, 100
	DangerDark = Color3.fromRGB(180, 55, 50),     -- was 219, 63, 60

	Accent = Color3.fromRGB(130, 115, 220),       -- was 156, 136, 255
	AccentHover = Color3.fromRGB(145, 130, 230),  -- was 176, 156, 255

	Warning = Color3.fromRGB(220, 155, 60),       -- was 255, 179, 71
	WarningHover = Color3.fromRGB(235, 170, 75),  -- was 255, 199, 91

	TextPrimary = Color3.fromRGB(225, 230, 240),  -- slightly less bright
	TextSecondary = Color3.fromRGB(145, 155, 170),
	TextMuted = Color3.fromRGB(100, 110, 125),

	InputBackground = Color3.fromRGB(25, 28, 35),
	InputBorder = Color3.fromRGB(50, 55, 68),

	Border = Color3.fromRGB(40, 45, 58),
	BorderLight = Color3.fromRGB(55, 60, 72),

	ButtonBackground = Color3.fromRGB(45, 50, 62),

	Unselected = Color3.fromRGB(55, 60, 72),
	SelectedBg = Color3.fromRGB(60, 120, 180), -- aligned with PrimaryDark

	SkillCheckSuccess = Color3.fromRGB(60, 150, 100),
	SkillCheckFailure = Color3.fromRGB(200, 70, 65),
	ConditionGated = Color3.fromRGB(95, 85, 140),   -- calmer purple
	QuestGated = Color3.fromRGB(220, 155, 60),      -- match Warning

	ResponseToNode = Color3.fromRGB(100, 200, 200),
}

Constants.SIZES = {
	TopBarHeight = 48,
	TreeViewWidth = 0.55,
	EditorWidth = 0.45,

	InputHeight = 36,
	ButtonHeight = 36,
	InputHeightMultiLine = 90,
	LabelHeight = 22,

	Padding = 12,
	PaddingSmall = 8,
	PaddingLarge = 15,

	BorderWidth = 1,
	CornerRadius = 6,

	ScrollBarThickness = 6,
	ScrollBarThicknessThin = 5
}

Constants.FONTS = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold
}

Constants.TEXT_SIZES = {
	Small = 12,
	Normal = 14,
	Medium = 15,
	Large = 16,
	ExtraLarge = 18
}

return Constants