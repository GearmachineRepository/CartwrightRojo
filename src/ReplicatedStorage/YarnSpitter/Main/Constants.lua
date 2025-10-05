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

	Primary = Color3.fromRGB(88, 166, 255),
	PrimaryHover = Color3.fromRGB(108, 186, 255),
	PrimaryDark = Color3.fromRGB(68, 146, 235),

	Success = Color3.fromRGB(72, 187, 120),
	SuccessHover = Color3.fromRGB(92, 207, 140),
	SuccessDark = Color3.fromRGB(52, 167, 100),

	Danger = Color3.fromRGB(239, 83, 80),
	DangerHover = Color3.fromRGB(255, 103, 100),
	DangerDark = Color3.fromRGB(219, 63, 60),

	Accent = Color3.fromRGB(156, 136, 255),
	AccentHover = Color3.fromRGB(176, 156, 255),

	Warning = Color3.fromRGB(255, 179, 71),
	WarningHover = Color3.fromRGB(255, 199, 91),

	TextPrimary = Color3.fromRGB(240, 243, 250),
	TextSecondary = Color3.fromRGB(160, 170, 185),
	TextMuted = Color3.fromRGB(110, 120, 135),

	InputBackground = Color3.fromRGB(25, 28, 35),
	InputBorder = Color3.fromRGB(55, 60, 72),

	Border = Color3.fromRGB(45, 50, 62),
	BorderLight = Color3.fromRGB(60, 65, 77),

	ButtonBackground = Color3.fromRGB(50, 55, 67),

	Unselected = Color3.fromRGB(60, 65, 77),
	SelectedBg = Color3.fromRGB(68, 146, 235),

	SkillCheckSuccess = Color3.fromRGB(72, 187, 120),
	SkillCheckFailure = Color3.fromRGB(239, 83, 80),
	ConditionGated = Color3.fromRGB(156, 136, 255),
	QuestGated = Color3.fromRGB(255, 179, 71),
}

Constants.SIZES = {
	TopBarHeight = 48,
	TreeViewWidth = 0.25,
	EditorWidth = 0.75,

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