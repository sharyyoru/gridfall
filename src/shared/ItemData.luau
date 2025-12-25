-- Gridfall Item Data
-- Default weapons and items database

local Types = require(script.Parent.Types)

local ItemData = {}

ItemData.Weapons = {
	-- Kinetic Weapons
	{
		Id = "kinetic_auto_1",
		Name = "Origin Story",
		Type = "Auto Rifle",
		Slot = "Kinetic",
		Rarity = "Legendary",
		Power = 1350,
		Magazine = 40,
		ReserveAmmo = 320,
		Damage = 18,
		FireRate = 600,
		Icon = "rbxassetid://0",
	},
	{
		Id = "kinetic_scout_1",
		Name = "Night Watch",
		Type = "Scout Rifle",
		Slot = "Kinetic",
		Rarity = "Legendary",
		Power = 1350,
		Magazine = 16,
		ReserveAmmo = 160,
		Damage = 45,
		FireRate = 180,
		Icon = "rbxassetid://0",
	},
	{
		Id = "kinetic_hc_1",
		Name = "Midnight Coup",
		Type = "Hand Cannon",
		Slot = "Kinetic",
		Rarity = "Legendary",
		Power = 1355,
		Magazine = 12,
		ReserveAmmo = 96,
		Damage = 68,
		FireRate = 140,
		Icon = "rbxassetid://0",
	},
	
	-- Energy Weapons
	{
		Id = "energy_smg_1",
		Name = "Riskrunner",
		Type = "SMG",
		Slot = "Energy",
		Rarity = "Exotic",
		Power = 1360,
		Magazine = 37,
		ReserveAmmo = 296,
		Damage = 15,
		FireRate = 900,
		Icon = "rbxassetid://0",
	},
	{
		Id = "energy_auto_1",
		Name = "Gnawing Hunger",
		Type = "Auto Rifle",
		Slot = "Energy",
		Rarity = "Legendary",
		Power = 1350,
		Magazine = 45,
		ReserveAmmo = 360,
		Damage = 17,
		FireRate = 600,
		Icon = "rbxassetid://0",
	},
	
	-- Power Weapons
	{
		Id = "power_rocket_1",
		Name = "Gjallarhorn",
		Type = "Rocket Launcher",
		Slot = "Power",
		Rarity = "Exotic",
		Power = 1365,
		Magazine = 1,
		ReserveAmmo = 6,
		Damage = 1200,
		FireRate = 15,
		Icon = "rbxassetid://0",
	},
	{
		Id = "power_sniper_1",
		Name = "Whisper of the Worm",
		Type = "Sniper",
		Slot = "Power",
		Rarity = "Exotic",
		Power = 1360,
		Magazine = 3,
		ReserveAmmo = 18,
		Damage = 450,
		FireRate = 72,
		Icon = "rbxassetid://0",
	},
	{
		Id = "power_sword_1",
		Name = "Falling Guillotine",
		Type = "Sword",
		Slot = "Power",
		Rarity = "Legendary",
		Power = 1355,
		Magazine = 60,
		ReserveAmmo = 60,
		Damage = 200,
		FireRate = 45,
		Icon = "rbxassetid://0",
	},
} :: {Types.WeaponData}

function ItemData.GetWeaponById(id: string): Types.WeaponData?
	for _, weapon in ipairs(ItemData.Weapons) do
		if weapon.Id == id then
			return weapon
		end
	end
	return nil
end

function ItemData.GetWeaponsBySlot(slot: Types.WeaponSlot): {Types.WeaponData}
	local weapons = {}
	for _, weapon in ipairs(ItemData.Weapons) do
		if weapon.Slot == slot then
			table.insert(weapons, weapon)
		end
	end
	return weapons
end

return ItemData
