-- Gridfall UI LocalScript
-- Creates and manages all UI screens

print("[UI] Starting UI initialization...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Load UI components with error handling
local success, err = pcall(function()
	local HUDComponent = require(script:WaitForChild("HUD", 5))
	local InventoryComponent = require(script:WaitForChild("Inventory", 5))
	
	-- Create HUD
	local hudScreen = HUDComponent.Create(playerGui)
	print("[UI] HUD created")
	
	-- Create Inventory Screen  
	local inventoryScreen = InventoryComponent.Create(playerGui)
	print("[UI] Inventory created")
end)

if not success then
	warn("[UI] ERROR creating UI: " .. tostring(err))
else
	print("[UI] All UI components initialized successfully")
end
