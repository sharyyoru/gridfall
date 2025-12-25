-- Gridfall UI Module Index
-- Creates and manages all UI screens

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))

-- UI Components
local HUDComponent = require(script.HUD)
local InventoryComponent = require(script.Inventory)

local UI = {}

function UI.Init()
	-- Create HUD
	HUDComponent.Create(playerGui)
	
	-- Create Inventory Screen
	InventoryComponent.Create(playerGui)
	
	print("[UI] All UI components created")
end

-- Auto-initialize
UI.Init()

return UI
