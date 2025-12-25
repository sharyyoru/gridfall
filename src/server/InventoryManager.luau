-- Gridfall Inventory Manager
-- Handles player inventories, equipment, and weapon state

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants
local ItemData = Shared.ItemData
local ArmorData = Shared.ArmorData
local Types = Shared.Types

local InventoryManager = {}

-- Player inventories storage
local playerInventories: {[Player]: Types.PlayerInventory} = {}

function InventoryManager.CreateDefaultInventory(): Types.PlayerInventory
	-- Give players starter gear
	local starterWeapons = {
		ItemData.GetWeaponById("kinetic_auto_1"),
		ItemData.GetWeaponById("energy_smg_1"),
		ItemData.GetWeaponById("power_rocket_1"),
	}
	
	local starterArmor = {
		ArmorData.GetArmorById("helmet_titan_1"),
		ArmorData.GetArmorById("chest_titan_1"),
		ArmorData.GetArmorById("arms_titan_1"),
		ArmorData.GetArmorById("legs_titan_1"),
		ArmorData.GetArmorById("class_titan_1"),
	}
	
	local inventory: Types.PlayerInventory = {
		Weapons = {},
		Armor = {},
		EquippedWeapons = {
			Kinetic = nil,
			Energy = nil,
			Power = nil,
		},
		EquippedArmor = {
			Helmet = nil,
			Chest = nil,
			Arms = nil,
			Legs = nil,
			Class = nil,
		},
		CurrentWeaponSlot = nil,
	}
	
	-- Add starter weapons
	for _, weapon in ipairs(starterWeapons) do
		if weapon then
			table.insert(inventory.Weapons, weapon)
		end
	end
	
	-- Add starter armor
	for _, armor in ipairs(starterArmor) do
		if armor then
			table.insert(inventory.Armor, armor)
		end
	end
	
	-- Auto-equip starter gear
	if inventory.Weapons[1] then
		inventory.EquippedWeapons.Kinetic = inventory.Weapons[1]
	end
	if inventory.Weapons[2] then
		inventory.EquippedWeapons.Energy = inventory.Weapons[2]
	end
	if inventory.Weapons[3] then
		inventory.EquippedWeapons.Power = inventory.Weapons[3]
	end
	
	for _, armor in ipairs(inventory.Armor) do
		if armor then
			inventory.EquippedArmor[armor.Slot] = armor
		end
	end
	
	return inventory
end

function InventoryManager.GetPlayerInventory(player: Player): Types.PlayerInventory?
	return playerInventories[player]
end

function InventoryManager.EquipWeapon(player: Player, weaponId: string, slot: Types.WeaponSlot): boolean
	local inventory = playerInventories[player]
	if not inventory then return false end
	
	-- Find weapon in inventory
	local weapon: Types.WeaponData? = nil
	for _, w in ipairs(inventory.Weapons) do
		if w.Id == weaponId then
			weapon = w
			break
		end
	end
	
	if not weapon then return false end
	if weapon.Slot ~= slot then return false end
	
	-- Equip the weapon
	inventory.EquippedWeapons[slot] = weapon
	inventory.CurrentWeaponSlot = slot
	
	-- Fire event to client
	local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if Remotes then
		local event = Remotes:FindFirstChild("WeaponEquipped")
		if event then
			event:FireClient(player, weapon, slot)
		end
		
		local updateEvent = Remotes:FindFirstChild("InventoryUpdated")
		if updateEvent then
			updateEvent:FireClient(player, inventory)
		end
	end
	
	return true
end

function InventoryManager.UnequipWeapon(player: Player): boolean
	local inventory = playerInventories[player]
	if not inventory then return false end
	
	inventory.CurrentWeaponSlot = nil
	
	-- Fire event to client
	local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if Remotes then
		local event = Remotes:FindFirstChild("WeaponUnequipped")
		if event then
			event:FireClient(player)
		end
	end
	
	return true
end

function InventoryManager.EquipArmor(player: Player, armorId: string): boolean
	local inventory = playerInventories[player]
	if not inventory then return false end
	
	-- Find armor in inventory
	local armor: Types.ArmorData? = nil
	for _, a in ipairs(inventory.Armor) do
		if a.Id == armorId then
			armor = a
			break
		end
	end
	
	if not armor then return false end
	
	-- Equip the armor
	inventory.EquippedArmor[armor.Slot] = armor
	
	-- Fire event to client
	local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if Remotes then
		local event = Remotes:FindFirstChild("ArmorEquipped")
		if event then
			event:FireClient(player, armor)
		end
		
		local updateEvent = Remotes:FindFirstChild("InventoryUpdated")
		if updateEvent then
			updateEvent:FireClient(player, inventory)
		end
	end
	
	return true
end

function InventoryManager.SetupRemotes()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not Remotes then return end
	
	-- GetInventory
	local getInventory = Remotes:FindFirstChild("GetInventory") :: RemoteFunction?
	if getInventory then
		getInventory.OnServerInvoke = function(player: Player)
			return playerInventories[player]
		end
	end
	
	-- EquipWeapon
	local equipWeapon = Remotes:FindFirstChild("EquipWeapon") :: RemoteFunction?
	if equipWeapon then
		equipWeapon.OnServerInvoke = function(player: Player, weaponId: string, slot: string)
			return InventoryManager.EquipWeapon(player, weaponId, slot :: Types.WeaponSlot)
		end
	end
	
	-- UnequipWeapon
	local unequipWeapon = Remotes:FindFirstChild("UnequipWeapon") :: RemoteFunction?
	if unequipWeapon then
		unequipWeapon.OnServerInvoke = function(player: Player)
			return InventoryManager.UnequipWeapon(player)
		end
	end
	
	-- EquipArmor
	local equipArmor = Remotes:FindFirstChild("EquipArmor") :: RemoteFunction?
	if equipArmor then
		equipArmor.OnServerInvoke = function(player: Player, armorId: string)
			return InventoryManager.EquipArmor(player, armorId)
		end
	end
end

function InventoryManager.OnPlayerAdded(player: Player)
	-- Create inventory for player
	playerInventories[player] = InventoryManager.CreateDefaultInventory()
	print("[InventoryManager] Created inventory for " .. player.Name)
end

function InventoryManager.OnPlayerRemoving(player: Player)
	-- Save inventory here if needed (DataStore)
	playerInventories[player] = nil
end

function InventoryManager.Init()
	-- Setup remote handlers
	task.spawn(InventoryManager.SetupRemotes)
	
	-- Connect player events
	Players.PlayerAdded:Connect(InventoryManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(InventoryManager.OnPlayerRemoving)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		InventoryManager.OnPlayerAdded(player)
	end
	
	print("[InventoryManager] Initialized")
end

return InventoryManager
