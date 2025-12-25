-- Gridfall Input Controller
-- Handles all player input including inventory toggle

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local InputController = {}

local player = Players.LocalPlayer
local isInventoryOpen = false

-- Callbacks
local onInventoryToggle: ((boolean) -> ())?
local onWeaponSlotPressed: ((number) -> ())?

function InputController.SetInventoryCallback(callback: (boolean) -> ())
	onInventoryToggle = callback
end

function InputController.SetWeaponSlotCallback(callback: (number) -> ())
	onWeaponSlotPressed = callback
end

function InputController.IsInventoryOpen(): boolean
	return isInventoryOpen
end

function InputController.ToggleInventory()
	isInventoryOpen = not isInventoryOpen
	
	if onInventoryToggle then
		onInventoryToggle(isInventoryOpen)
	end
	
	-- Lock/unlock mouse based on inventory state
	if isInventoryOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

function InputController.OnInputBegan(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	
	-- Tab - Toggle Inventory
	if input.KeyCode == Constants.UI.InventoryToggleKey then
		InputController.ToggleInventory()
		return
	end
	
	-- Number keys 1-3 for weapon slots
	if input.KeyCode == Enum.KeyCode.One then
		if onWeaponSlotPressed then
			onWeaponSlotPressed(1)
		end
	elseif input.KeyCode == Enum.KeyCode.Two then
		if onWeaponSlotPressed then
			onWeaponSlotPressed(2)
		end
	elseif input.KeyCode == Enum.KeyCode.Three then
		if onWeaponSlotPressed then
			onWeaponSlotPressed(3)
		end
	end
	
	-- Escape to close inventory
	if input.KeyCode == Enum.KeyCode.Escape and isInventoryOpen then
		isInventoryOpen = false
		if onInventoryToggle then
			onInventoryToggle(false)
		end
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end

function InputController.Init()
	-- Input events
	UserInputService.InputBegan:Connect(InputController.OnInputBegan)
	
	-- Don't lock mouse on startup - let Roblox handle it naturally
	-- Mouse will lock when player clicks on game
	
	print("[InputController] Initialized")
end

return InputController
