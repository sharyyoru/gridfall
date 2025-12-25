-- Gridfall Input Controller
-- Handles all player input including inventory toggle and weapon switching

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

local InputController = {}

local player = Players.LocalPlayer
local isInventoryOpen = false
local inventoryScreen = nil

function InputController.SetInventoryScreen(screen)
	inventoryScreen = screen
end

function InputController.IsInventoryOpen(): boolean
	return isInventoryOpen
end

function InputController.ToggleInventory()
	isInventoryOpen = not isInventoryOpen
	
	if inventoryScreen then
		inventoryScreen.Visible = isInventoryOpen
	end
	
	print("[InputController] Inventory " .. (isInventoryOpen and "OPENED" or "CLOSED"))
end

function InputController.EquipWeaponSlot(slotNumber: number)
	local character = player.Character
	if not character then return end
	
	local backpack = player:FindFirstChild("Backpack")
	local tools = {}
	
	-- Get tools from backpack
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				table.insert(tools, tool)
			end
		end
	end
	
	-- Get currently equipped tool
	for _, tool in ipairs(character:GetChildren()) do
		if tool:IsA("Tool") then
			table.insert(tools, tool)
		end
	end
	
	-- Sort tools by name for consistent ordering
	table.sort(tools, function(a, b) return a.Name < b.Name end)
	
	-- Equip the tool at slotNumber
	if tools[slotNumber] then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			-- Unequip current tool first
			humanoid:UnequipTools()
			-- Equip selected tool
			humanoid:EquipTool(tools[slotNumber])
			print("[InputController] Equipped: " .. tools[slotNumber].Name)
		end
	end
end

function InputController.OnInputBegan(input: InputObject, gameProcessed: boolean)
	-- Allow Tab even if gameProcessed (so it works when clicking on UI)
	if input.KeyCode == Enum.KeyCode.Tab then
		InputController.ToggleInventory()
		return
	end
	
	if gameProcessed then return end
	
	-- Number keys 1-3 for weapon slots
	if input.KeyCode == Enum.KeyCode.One then
		InputController.EquipWeaponSlot(1)
	elseif input.KeyCode == Enum.KeyCode.Two then
		InputController.EquipWeaponSlot(2)
	elseif input.KeyCode == Enum.KeyCode.Three then
		InputController.EquipWeaponSlot(3)
	end
	
	-- Escape to close inventory
	if input.KeyCode == Enum.KeyCode.Escape and isInventoryOpen then
		isInventoryOpen = false
		if inventoryScreen then
			inventoryScreen.Visible = false
		end
	end
end

function InputController.Init()
	-- Input events
	UserInputService.InputBegan:Connect(InputController.OnInputBegan)
	
	print("[InputController] Initialized")
end

return InputController
