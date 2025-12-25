-- Gridfall Server Main
-- Initializes all server-side systems

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

-- Server modules
local GameModeDisabler = require(script.GameModeDisabler)
local SpawnManager = require(script.SpawnManager)
local CharacterManager = require(script.CharacterManager)
local InventoryManager = require(script.InventoryManager)

-- Create RemoteEvents and RemoteFunctions
local Remotes = Instance.new("Folder")
Remotes.Name = "Remotes"
Remotes.Parent = ReplicatedStorage

local Events = {
	"WeaponEquipped",
	"WeaponUnequipped",
	"ArmorEquipped",
	"InventoryUpdated",
	"CameraModeChanged",
}

local Functions = {
	"GetInventory",
	"EquipWeapon",
	"UnequipWeapon",
	"EquipArmor",
}

for _, eventName in ipairs(Events) do
	local event = Instance.new("RemoteEvent")
	event.Name = eventName
	event.Parent = Remotes
end

for _, funcName in ipairs(Functions) do
	local func = Instance.new("RemoteFunction")
	func.Name = funcName
	func.Parent = Remotes
end

-- Initialize systems (GameModeDisabler first to clean up existing systems)
GameModeDisabler.Init()
SpawnManager.Init()
CharacterManager.Init()
InventoryManager.Init()

print("[Gridfall] Server initialized successfully")