-- Gridfall Armor Data
-- Default armor pieces database

local Types = require(script.Parent.Types)

local ArmorData = {}

ArmorData.Armor = {
	-- Helmets
	{
		Id = "helmet_titan_1",
		Name = "Sentinel Helm",
		Slot = "Helmet",
		Rarity = "Legendary",
		Power = 1350,
		Mobility = 8,
		Resilience = 22,
		Recovery = 12,
		Icon = "rbxassetid://0",
	},
	{
		Id = "helmet_titan_2",
		Name = "Phoenix Protocol",
		Slot = "Helmet",
		Rarity = "Exotic",
		Power = 1360,
		Mobility = 10,
		Resilience = 20,
		Recovery = 15,
		Icon = "rbxassetid://0",
	},
	
	-- Chest Armor
	{
		Id = "chest_titan_1",
		Name = "Plate of the Exile",
		Slot = "Chest",
		Rarity = "Legendary",
		Power = 1355,
		Mobility = 6,
		Resilience = 25,
		Recovery = 10,
		Icon = "rbxassetid://0",
	},
	{
		Id = "chest_titan_2",
		Name = "Cuirass of the Falling Star",
		Slot = "Chest",
		Rarity = "Exotic",
		Power = 1365,
		Mobility = 12,
		Resilience = 18,
		Recovery = 18,
		Icon = "rbxassetid://0",
	},
	
	-- Arms
	{
		Id = "arms_titan_1",
		Name = "Gauntlets of Nohr",
		Slot = "Arms",
		Rarity = "Legendary",
		Power = 1350,
		Mobility = 10,
		Resilience = 20,
		Recovery = 12,
		Icon = "rbxassetid://0",
	},
	{
		Id = "arms_titan_2",
		Name = "Synthoceps",
		Slot = "Arms",
		Rarity = "Exotic",
		Power = 1360,
		Mobility = 15,
		Resilience = 15,
		Recovery = 15,
		Icon = "rbxassetid://0",
	},
	
	-- Legs
	{
		Id = "legs_titan_1",
		Name = "Greaves of the Great Hunt",
		Slot = "Legs",
		Rarity = "Legendary",
		Power = 1350,
		Mobility = 12,
		Resilience = 18,
		Recovery = 14,
		Icon = "rbxassetid://0",
	},
	{
		Id = "legs_titan_2",
		Name = "Lion Rampant",
		Slot = "Legs",
		Rarity = "Exotic",
		Power = 1358,
		Mobility = 20,
		Resilience = 10,
		Recovery = 16,
		Icon = "rbxassetid://0",
	},
	
	-- Class Items
	{
		Id = "class_titan_1",
		Name = "Mark of the Unbroken",
		Slot = "Class",
		Rarity = "Legendary",
		Power = 1350,
		Mobility = 10,
		Resilience = 10,
		Recovery = 10,
		Icon = "rbxassetid://0",
	},
} :: {Types.ArmorData}

function ArmorData.GetArmorById(id: string): Types.ArmorData?
	for _, armor in ipairs(ArmorData.Armor) do
		if armor.Id == id then
			return armor
		end
	end
	return nil
end

function ArmorData.GetArmorBySlot(slot: Types.ArmorSlot): {Types.ArmorData}
	local armorPieces = {}
	for _, armor in ipairs(ArmorData.Armor) do
		if armor.Slot == slot then
			table.insert(armorPieces, armor)
		end
	end
	return armorPieces
end

return ArmorData
