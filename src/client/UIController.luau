-- Gridfall UI Controller
-- Manages all UI components and state

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local InputController = require(script.Parent.InputController)

local UIController = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- UI References (will be populated when UI loads)
local hudScreen: ScreenGui?
local inventoryScreen: ScreenGui?
local currentInventory = nil

function UIController.SetInventory(inventory)
	currentInventory = inventory
	UIController.UpdateHUD()
	UIController.UpdateInventoryUI()
end

function UIController.UpdateHUD()
	-- HUD updates handled by HUD script
end

function UIController.UpdateInventoryUI()
	-- Inventory updates handled by Inventory script
end

function UIController.ShowInventory()
	local gridFallUI = playerGui:FindFirstChild("GridfallUI")
	if gridFallUI then
		local inventory = gridFallUI:FindFirstChild("InventoryScreen")
		if inventory then
			inventory.Enabled = true
		end
	end
end

function UIController.HideInventory()
	local gridFallUI = playerGui:FindFirstChild("GridfallUI")
	if gridFallUI then
		local inventory = gridFallUI:FindFirstChild("InventoryScreen")
		if inventory then
			inventory.Enabled = false
		end
	end
end

function UIController.OnInventoryToggle(isOpen: boolean)
	if isOpen then
		UIController.ShowInventory()
	else
		UIController.HideInventory()
	end
end

function UIController.SetupRemoteListeners()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not Remotes then return end
	
	local inventoryUpdated = Remotes:FindFirstChild("InventoryUpdated")
	if inventoryUpdated then
		inventoryUpdated.OnClientEvent:Connect(function(inventory)
			UIController.SetInventory(inventory)
		end)
	end
end

function UIController.FetchInitialInventory()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not Remotes then return end
	
	local getInventory = Remotes:FindFirstChild("GetInventory") :: RemoteFunction?
	if getInventory then
		local inventory = getInventory:InvokeServer()
		if inventory then
			UIController.SetInventory(inventory)
		end
	end
end

function UIController.Init()
	-- Register input callback
	InputController.SetInventoryCallback(UIController.OnInventoryToggle)
	
	-- Setup remote listeners
	UIController.SetupRemoteListeners()
	
	-- Fetch initial inventory after a short delay
	task.spawn(function()
		task.wait(1)
		UIController.FetchInitialInventory()
	end)
	
	print("[UIController] Initialized")
end

return UIController
