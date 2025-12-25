-- Gridfall Type Definitions
-- Shared types used across client and server

export type ItemRarity = "Common" | "Uncommon" | "Rare" | "Legendary" | "Exotic"

export type WeaponType = "Auto Rifle" | "Scout Rifle" | "Hand Cannon" | "Shotgun" | "Sniper" | "SMG" | "Rocket Launcher" | "Sword"

export type WeaponSlot = "Kinetic" | "Energy" | "Power"

export type ArmorSlot = "Helmet" | "Chest" | "Arms" | "Legs" | "Class"

export type WeaponData = {
	Id: string,
	Name: string,
	Type: WeaponType,
	Slot: WeaponSlot,
	Rarity: ItemRarity,
	Power: number,
	Magazine: number,
	ReserveAmmo: number,
	Damage: number,
	FireRate: number,
	Icon: string,
	Model: string?,
}

export type ArmorData = {
	Id: string,
	Name: string,
	Slot: ArmorSlot,
	Rarity: ItemRarity,
	Power: number,
	Mobility: number,
	Resilience: number,
	Recovery: number,
	Icon: string,
	Model: string?,
}

export type PlayerStats = {
	Power: number,
	Mobility: number,
	Resilience: number,
	Recovery: number,
}

export type PlayerInventory = {
	Weapons: {WeaponData},
	Armor: {ArmorData},
	EquippedWeapons: {[WeaponSlot]: WeaponData?},
	EquippedArmor: {[ArmorSlot]: ArmorData?},
	CurrentWeaponSlot: WeaponSlot?,
}

export type CameraMode = "FPP" | "TPP"

return nil
