-- Gridfall Constants
-- Game-wide constants and configuration

local Constants = {}

-- Spawn Configuration
Constants.SPAWN = {
	MainSpawnName = "MainSpawn",
	DefaultMapName = "Overheat",
	RespawnTime = 3,
}

-- Camera Configuration
Constants.CAMERA = {
	FPP_FOV = 70,
	TPP_FOV = 65,
	TPP_OFFSET = Vector3.new(2.5, 2, 8),
	TPP_TRANSITION_TIME = 0.3,
	FPP_TRANSITION_TIME = 0.2,
}

-- Character Configuration
Constants.CHARACTER = {
	DefaultWalkSpeed = 16,
	SprintSpeed = 24,
	DefaultJumpPower = 50,
}

-- Soldier Appearance (Default look for all players)
Constants.SOLDIER_APPEARANCE = {
	BodyColors = {
		HeadColor = BrickColor.new("Nougat"),
		TorsoColor = BrickColor.new("Dark stone grey"),
		LeftArmColor = BrickColor.new("Nougat"),
		RightArmColor = BrickColor.new("Nougat"),
		LeftLegColor = BrickColor.new("Dark stone grey"),
		RightLegColor = BrickColor.new("Dark stone grey"),
	},
	-- These will be applied as default clothing
	DefaultShirtId = "rbxassetid://6536112663", -- Military style shirt
	DefaultPantsId = "rbxassetid://6536113682", -- Military style pants
}

-- UI Configuration
Constants.UI = {
	InventoryToggleKey = Enum.KeyCode.Tab,
	PrimaryColor = Color3.fromRGB(65, 185, 220),
	SecondaryColor = Color3.fromRGB(255, 200, 50),
	BackgroundColor = Color3.fromRGB(20, 25, 35),
	TextColor = Color3.fromRGB(240, 240, 240),
	RarityColors = {
		Common = Color3.fromRGB(195, 195, 195),
		Uncommon = Color3.fromRGB(55, 180, 55),
		Rare = Color3.fromRGB(80, 130, 255),
		Legendary = Color3.fromRGB(160, 80, 200),
		Exotic = Color3.fromRGB(255, 200, 50),
	},
}

-- Equipment Slots
Constants.EQUIPMENT_SLOTS = {
	"Helmet",
	"Chest",
	"Arms",
	"Legs",
	"Class",
}

-- Weapon Slots
Constants.WEAPON_SLOTS = {
	"Kinetic",
	"Energy",
	"Power",
}

-- Inventory
Constants.INVENTORY = {
	MaxWeaponSlots = 9,
	MaxArmorSlots = 10,
}

return Constants
