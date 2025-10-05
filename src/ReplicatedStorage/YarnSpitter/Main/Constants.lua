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
	"DialogFlag",
	"HasQuest",
	"CompletedQuest",
	"CanTurnInQuest",
	"HasReputation",
	"HasItem",
	"Level",
	"HasSkill"
}

Constants.COLORS = {
	Background = Color3.fromRGB(42, 43, 48),
	BackgroundDark = Color3.fromRGB(35, 36, 41),
	BackgroundLight = Color3.fromRGB(58, 60, 68),

	Panel = Color3.fromRGB(50, 52, 58),
	PanelHover = Color3.fromRGB(68, 72, 82),

	Primary = Color3.fromRGB(100, 150, 230),
	PrimaryHover = Color3.fromRGB(130, 175, 245),

	Accent = Color3.fromRGB(130, 110, 220),
	AccentHover = Color3.fromRGB(155, 135, 240),

	Success = Color3.fromRGB(90, 175, 120),
	SuccessHover = Color3.fromRGB(115, 200, 145),
	SuccessDark = Color3.fromRGB(75, 158, 105),

	Danger = Color3.fromRGB(220, 90, 90),
	DangerHover = Color3.fromRGB(245, 120, 120),
	DangerDark = Color3.fromRGB(200, 75, 75),

	Warning = Color3.fromRGB(230, 175, 75),

	Border = Color3.fromRGB(68, 71, 78),
	BorderLight = Color3.fromRGB(85, 88, 96),

	Selected = Color3.fromRGB(100, 150, 230),
	SelectedBg = Color3.fromRGB(75, 110, 170),
	Unselected = Color3.fromRGB(56, 58, 64),

	InputBackground = Color3.fromRGB(56, 58, 65),
	InputBorder = Color3.fromRGB(75, 78, 86),
	ButtonBackground = Color3.fromRGB(62, 65, 72),
	DropdownBackground = Color3.fromRGB(52, 54, 61),

	TextPrimary = Color3.fromRGB(225, 228, 232),
	TextSecondary = Color3.fromRGB(175, 180, 188),
	TextMuted = Color3.fromRGB(130, 136, 146)
}

Constants.SIZES = {
	TopBarHeight = 48,
	TreeViewWidth = 0.35,
	EditorWidth = 0.65,

	ButtonHeight = 34,
	InputHeight = 34,
	InputHeightMultiLine = 90,
	LabelHeight = 22,

	Padding = 14,
	PaddingSmall = 8,
	PaddingLarge = 20,

	BorderWidth = 1,
	CornerRadius = 6,

	ScrollBarThickness = 8,
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
	Large = 17,
	ExtraLarge = 19
}

return Constants