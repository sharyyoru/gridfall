-- Gridfall UI LocalScript
-- Creates and manages all UI screens

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules to load
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if Shared then
	Shared = require(Shared)
end

-- UI Components
local HUDComponent = require(script:WaitForChild("HUD"))
local InventoryComponent = require(script:WaitForChild("Inventory"))

-- Create HUD
local hudScreen = HUDComponent.Create(playerGui)
print("[UI] HUD created")

-- Create Inventory Screen
local inventoryScreen = InventoryComponent.Create(playerGui)
print("[UI] Inventory created")

print("[UI] All UI components initialized successfully")
