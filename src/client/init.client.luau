-- Gridfall Client Main
-- Complete rewrite with all fixes

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- DISABLE ALL ROBLOX DEFAULT UIS
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

---------------------------------------
-- DISABLE BLASTER SYSTEM COMPLETELY
---------------------------------------
local function disableBlasterScripts()
	-- Find and disable Blaster scripts in ReplicatedStorage
	local blaster = ReplicatedStorage:FindFirstChild("Blaster")
	if blaster then
		local scripts = blaster:FindFirstChild("Scripts")
		if scripts then
			for _, script in ipairs(scripts:GetDescendants()) do
				if script:IsA("LocalScript") or script:IsA("ModuleScript") then
					-- Can't disable directly, but we can track what's there
					print("[Client] Found Blaster script:", script.Name)
				end
			end
		end
	end
end

-- Try to disable Blaster
pcall(disableBlasterScripts)

-- DO NOT unbind Roblox's essential movement/camera actions!
-- We were accidentally unbinding WASD controls before.
-- Instead, just don't interfere with ContextActionService at all.
print("[Client] Keeping all ContextActionService bindings intact")

---------------------------------------
-- MENU MANAGER (global menu state for blocking inputs)
---------------------------------------
local MenuManager = {
	_openMenus = {},
	_isAnyMenuOpen = false
}

function MenuManager:OpenMenu(menuName)
	self._openMenus[menuName] = true
	self._isAnyMenuOpen = true
	self:_updateInputBlocking()
end

function MenuManager:CloseMenu(menuName)
	self._openMenus[menuName] = nil
	self._isAnyMenuOpen = next(self._openMenus) ~= nil
	self:_updateInputBlocking()
end

function MenuManager:IsAnyMenuOpen()
	return self._isAnyMenuOpen
end

function MenuManager:_updateInputBlocking()
	-- DISABLED - This was blocking Roblox's default movement
	-- Don't bind any ContextActionService actions that interfere with movement
	if self._isAnyMenuOpen then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		-- No action needed - don't interfere with Roblox's input system
	end
end

-- Make MenuManager globally accessible
_G.GridfallMenuManager = MenuManager

---------------------------------------
-- STATE
---------------------------------------
local currentEquippedSlot = 0 -- 0 = none, 1-3 = slot number
local isInventoryOpen = false
local weaponTools = {} -- {[1] = Tool, [2] = Tool, ...}
local hudScreen = nil
local inventoryScreen = nil

---------------------------------------
-- CAMERA SYSTEM (aggressive enforcement)
---------------------------------------
local TPP_MIN_ZOOM = 8
local TPP_MAX_ZOOM = 20
local FPP_MIN_ZOOM = 0.5
local FPP_MAX_ZOOM = 0.5
local currentCameraMode = "TPP"

local function setCameraMode(mode)
	currentCameraMode = mode
	if mode == "FPP" then
		player.CameraMinZoomDistance = FPP_MIN_ZOOM
		player.CameraMaxZoomDistance = FPP_MAX_ZOOM
		player.CameraMode = Enum.CameraMode.Classic
		-- Show crosshair in FPP
		if hudScreen then
			local crosshair = hudScreen:FindFirstChild("Crosshair")
			if crosshair then crosshair.Visible = true end
		end
		print("[Camera] Switched to FPP")
	else
		player.CameraMinZoomDistance = TPP_MIN_ZOOM
		player.CameraMaxZoomDistance = TPP_MAX_ZOOM
		player.CameraMode = Enum.CameraMode.Classic
		-- Hide crosshair in TPP
		if hudScreen then
			local crosshair = hudScreen:FindFirstChild("Crosshair")
			if crosshair then crosshair.Visible = false end
		end
		-- Force camera to zoom out
		local camera = workspace.CurrentCamera
		if camera and player.Character then
			local hrp = player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local lookDir = camera.CFrame.LookVector
				camera.CFrame = CFrame.new(hrp.Position - lookDir * TPP_MIN_ZOOM, hrp.Position)
			end
		end
		print("[Camera] Switched to TPP")
	end
end

-- Continuously enforce camera settings (Blaster keeps overriding)
RunService.RenderStepped:Connect(function()
	-- Always enforce CameraMode to Classic (not LockFirstPerson)
	if player.CameraMode ~= Enum.CameraMode.Classic then
		player.CameraMode = Enum.CameraMode.Classic
	end
	
	if currentCameraMode == "TPP" then
		if player.CameraMinZoomDistance < TPP_MIN_ZOOM then
			player.CameraMinZoomDistance = TPP_MIN_ZOOM
		end
		if player.CameraMaxZoomDistance < TPP_MAX_ZOOM then
			player.CameraMaxZoomDistance = TPP_MAX_ZOOM
		end
	end
end)

-- Start in TPP after character loads
local function initCamera()
	task.wait(0.5)
	setCameraMode("TPP")
	print("[Camera] Initial TPP mode set")
end

if player.Character then
	task.spawn(initCamera)
end
player.CharacterAdded:Connect(function()
	task.spawn(initCamera)
end)

---------------------------------------
-- MOVEMENT SYSTEM (DISABLED - using normal humanoid movement)
---------------------------------------
-- BodyVelocity was causing sinking and physics issues
-- We now use normal Roblox humanoid movement instead

local function removeBodyVelocity(character)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	
	-- Remove any existing BodyVelocity that was causing issues
	local existing = hrp:FindFirstChild("GridfallMover")
	if existing then 
		existing:Destroy()
		print("[Movement] Removed problematic BodyVelocity")
	end
end

-- Clean up any existing BodyVelocity
if player.Character then
	task.spawn(function() removeBodyVelocity(player.Character) end)
end
player.CharacterAdded:Connect(function(char)
	task.spawn(function() removeBodyVelocity(char) end)
end)

print("[Client] BodyVelocity movement system DISABLED - using normal humanoid movement")

---------------------------------------
-- VIEWMODEL ARMS FIX (replace grey arms with player avatar arms)
---------------------------------------
local function replaceViewModelArms()
	-- Find the ViewModel in workspace (Blaster system parents it there when equipped)
	local viewModel = workspace:FindFirstChild("ViewModel", true)
	if not viewModel then return end
	
	local character = player.Character
	if not character then return end
	
	-- Get player's arm colors/properties from character
	local leftArm = character:FindFirstChild("Left Arm") or character:FindFirstChild("LeftUpperArm")
	local rightArm = character:FindFirstChild("Right Arm") or character:FindFirstChild("RightUpperArm")
	
	if not leftArm or not rightArm then return end
	
	-- Find ViewModel arms and copy player's appearance
	for _, part in ipairs(viewModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local partName = part.Name:lower()
			if partName:find("left") and partName:find("arm") then
				part.Color = leftArm.Color
				part.Material = leftArm.Material
			elseif partName:find("right") and partName:find("arm") then
				part.Color = rightArm.Color
				part.Material = rightArm.Material
			elseif partName:find("arm") or partName:find("hand") then
				-- Generic arm/hand part - use right arm color
				part.Color = rightArm.Color
				part.Material = rightArm.Material
			end
		end
	end
	
	print("[ViewModel] Applied player arm colors to ViewModel")
end

-- Run arm replacement when character or workspace changes
task.spawn(function()
	while true do
		task.wait(0.5)
		if currentEquippedSlot > 0 then
			replaceViewModelArms()
		end
	end
end)

---------------------------------------
-- WEAPON SYSTEM
---------------------------------------
local function getWeaponTools()
	local tools = {}
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character
	
	if backpack then
		for _, item in ipairs(backpack:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(tools, item)
			end
		end
	end
	
	if character then
		for _, item in ipairs(character:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(tools, item)
			end
		end
	end
	
	table.sort(tools, function(a, b) return a.Name < b.Name end)
	return tools
end

local function updateWeaponSlots()
	weaponTools = getWeaponTools()
	
	if not hudScreen then return end
	local slotsFrame = hudScreen:FindFirstChild("WeaponSlots")
	if not slotsFrame then return end
	
	for i = 1, 3 do
		local slot = slotsFrame:FindFirstChild("Slot" .. i)
		if slot then
			local nameLabel = slot:FindFirstChild("WeaponName")
			if not nameLabel then
				nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "WeaponName"
				nameLabel.Size = UDim2.new(1, -6, 0, 12)
				nameLabel.Position = UDim2.new(0, 3, 1, -15)
				nameLabel.BackgroundTransparency = 1
				nameLabel.TextColor3 = Color3.new(1, 1, 1)
				nameLabel.TextSize = 8
				nameLabel.Font = Enum.Font.Gotham
				nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				nameLabel.Parent = slot
			end
			
			if weaponTools[i] then
				nameLabel.Text = weaponTools[i].Name
			else
				nameLabel.Text = "Empty"
			end
			
			-- Highlight equipped slot
			if i == currentEquippedSlot then
				slot.BackgroundColor3 = Color3.fromRGB(65, 185, 220)
				slot.BackgroundTransparency = 0.2
			else
				slot.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
				slot.BackgroundTransparency = 0.3
			end
		end
	end
end

local function equipWeaponSlot(slotNumber)
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	weaponTools = getWeaponTools()
	
	-- Toggle: if same slot pressed, unequip
	if currentEquippedSlot == slotNumber then
		humanoid:UnequipTools()
		currentEquippedSlot = 0
		setCameraMode("TPP")
		print("[Weapon] Unequipped - TPP mode")
	else
		-- Equip new weapon
		if weaponTools[slotNumber] then
			humanoid:UnequipTools()
			humanoid:EquipTool(weaponTools[slotNumber])
			currentEquippedSlot = slotNumber
			setCameraMode("FPP")
			print("[Weapon] Equipped: " .. weaponTools[slotNumber].Name .. " - FPP mode")
		end
	end
	
	updateWeaponSlots()
end

---------------------------------------
-- HUD
---------------------------------------
local function createHUD()
	local screen = Instance.new("ScreenGui")
	screen.Name = "GridfallHUD"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 10
	screen.Parent = playerGui
	
	-- Crosshair (hidden by default in TPP)
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0, 4, 0, 4)
	crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
	crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
	crosshair.BorderSizePixel = 0
	crosshair.Visible = false -- Hidden in TPP mode
	crosshair.Parent = screen
	Instance.new("UICorner", crosshair).CornerRadius = UDim.new(0, 2)
	
	-- Weapon slots
	local slotsFrame = Instance.new("Frame")
	slotsFrame.Name = "WeaponSlots"
	slotsFrame.Size = UDim2.new(0, 200, 0, 50)
	slotsFrame.Position = UDim2.new(0, 20, 1, -70)
	slotsFrame.BackgroundTransparency = 1
	slotsFrame.Parent = screen
	
	for i = 1, 3 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(0, 60, 0, 45)
		slot.Position = UDim2.new(0, (i-1) * 65, 0, 0)
		slot.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		slot.BackgroundTransparency = 0.3
		slot.Parent = slotsFrame
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 6)
		
		local numLabel = Instance.new("TextLabel")
		numLabel.Name = "SlotNumber"
		numLabel.Size = UDim2.new(0, 15, 0, 15)
		numLabel.Position = UDim2.new(0, 3, 0, 3)
		numLabel.BackgroundColor3 = Color3.fromRGB(65, 185, 220)
		numLabel.Text = tostring(i)
		numLabel.TextColor3 = Color3.new(1, 1, 1)
		numLabel.TextSize = 10
		numLabel.Font = Enum.Font.GothamBold
		numLabel.Parent = slot
		Instance.new("UICorner", numLabel).CornerRadius = UDim.new(0, 3)
	end
	
	-- Hint
	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(0, 300, 0, 20)
	hint.Position = UDim2.new(0.5, -150, 1, -25)
	hint.BackgroundTransparency = 1
	hint.Text = "1/2/3: Weapons | TAB: Inventory | Press again to unequip"
	hint.TextColor3 = Color3.fromRGB(150, 150, 150)
	hint.TextSize = 11
	hint.Font = Enum.Font.Gotham
	hint.Parent = screen
	
	return screen
end

---------------------------------------
-- INVENTORY SCREEN
---------------------------------------
local function createInventoryScreen()
	local screen = Instance.new("ScreenGui")
	screen.Name = "GridfallInventory"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.DisplayOrder = 20
	screen.Enabled = true
	screen.Parent = playerGui
	
	-- Main container (hidden by default)
	local container = Instance.new("Frame")
	container.Name = "Container"
	container.Size = UDim2.new(0.6, 0, 0.7, 0)
	container.Position = UDim2.new(0.2, 0, 0.15, 0)
	container.BackgroundColor3 = Color3.fromRGB(20, 25, 35)
	container.BackgroundTransparency = 0.1
	container.Visible = false
	container.Parent = screen
	Instance.new("UICorner", container).CornerRadius = UDim.new(0, 12)
	
	-- Header
	local header = Instance.new("TextLabel")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = Color3.fromRGB(30, 35, 50)
	header.Text = "INVENTORY"
	header.TextColor3 = Color3.new(1, 1, 1)
	header.TextSize = 24
	header.Font = Enum.Font.GothamBold
	header.Parent = container
	local headerCorner = Instance.new("UICorner", header)
	headerCorner.CornerRadius = UDim.new(0, 12)
	
	-- Weapons section
	local weaponsLabel = Instance.new("TextLabel")
	weaponsLabel.Size = UDim2.new(0, 100, 0, 30)
	weaponsLabel.Position = UDim2.new(0, 20, 0, 60)
	weaponsLabel.BackgroundTransparency = 1
	weaponsLabel.Text = "WEAPONS"
	weaponsLabel.TextColor3 = Color3.fromRGB(65, 185, 220)
	weaponsLabel.TextSize = 14
	weaponsLabel.Font = Enum.Font.GothamBold
	weaponsLabel.TextXAlignment = Enum.TextXAlignment.Left
	weaponsLabel.Parent = container
	
	-- Weapon slots in inventory
	for i = 1, 3 do
		local slot = Instance.new("Frame")
		slot.Name = "InvSlot" .. i
		slot.Size = UDim2.new(0, 150, 0, 80)
		slot.Position = UDim2.new(0, 20 + (i-1) * 160, 0, 100)
		slot.BackgroundColor3 = Color3.fromRGB(40, 45, 60)
		slot.Parent = container
		Instance.new("UICorner", slot).CornerRadius = UDim.new(0, 8)
		
		local slotNum = Instance.new("TextLabel")
		slotNum.Size = UDim2.new(0, 25, 0, 25)
		slotNum.Position = UDim2.new(0, 5, 0, 5)
		slotNum.BackgroundColor3 = Color3.fromRGB(65, 185, 220)
		slotNum.Text = tostring(i)
		slotNum.TextColor3 = Color3.new(1, 1, 1)
		slotNum.TextSize = 14
		slotNum.Font = Enum.Font.GothamBold
		slotNum.Parent = slot
		Instance.new("UICorner", slotNum).CornerRadius = UDim.new(0, 4)
		
		local weaponName = Instance.new("TextLabel")
		weaponName.Name = "WeaponName"
		weaponName.Size = UDim2.new(1, -10, 0, 20)
		weaponName.Position = UDim2.new(0, 5, 1, -25)
		weaponName.BackgroundTransparency = 1
		weaponName.Text = "Empty"
		weaponName.TextColor3 = Color3.new(1, 1, 1)
		weaponName.TextSize = 11
		weaponName.Font = Enum.Font.Gotham
		weaponName.TextTruncate = Enum.TextTruncate.AtEnd
		weaponName.TextXAlignment = Enum.TextXAlignment.Left
		weaponName.Parent = slot
	end
	
	-- Close hint
	local closeHint = Instance.new("TextLabel")
	closeHint.Size = UDim2.new(1, 0, 0, 30)
	closeHint.Position = UDim2.new(0, 0, 1, -30)
	closeHint.BackgroundTransparency = 1
	closeHint.Text = "Press TAB or ESC to close"
	closeHint.TextColor3 = Color3.fromRGB(120, 120, 120)
	closeHint.TextSize = 12
	closeHint.Font = Enum.Font.Gotham
	closeHint.Parent = container
	
	return screen, container
end

local function updateInventoryScreen()
	if not inventoryScreen then return end
	local container = inventoryScreen:FindFirstChild("Container")
	if not container then return end
	
	weaponTools = getWeaponTools()
	
	for i = 1, 3 do
		local slot = container:FindFirstChild("InvSlot" .. i)
		if slot then
			local nameLabel = slot:FindFirstChild("WeaponName")
			if nameLabel then
				if weaponTools[i] then
					nameLabel.Text = weaponTools[i].Name
				else
					nameLabel.Text = "Empty"
				end
			end
		end
	end
end

local function toggleInventory()
	isInventoryOpen = not isInventoryOpen
	
	if inventoryScreen then
		local container = inventoryScreen:FindFirstChild("Container")
		if container then
			container.Visible = isInventoryOpen
			if isInventoryOpen then
				-- AUTO-UNEQUIP weapons and switch to TPP when menu opens
				local character = player.Character
				if character then
					local humanoid = character:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid:UnequipTools()
					end
				end
				currentEquippedSlot = 0
				setCameraMode("TPP")
				updateWeaponSlots()
				updateInventoryScreen()
				MenuManager:OpenMenu("Inventory")
				print("[Inventory] OPENED - weapons unequipped, TPP mode")
			else
				MenuManager:CloseMenu("Inventory")
				print("[Inventory] CLOSED")
			end
		end
	end
end

---------------------------------------
-- INPUT HANDLING
---------------------------------------
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- Tab always works
	if input.KeyCode == Enum.KeyCode.Tab then
		toggleInventory()
		return
	end
	
	-- ESC closes inventory
	if input.KeyCode == Enum.KeyCode.Escape and isInventoryOpen then
		toggleInventory()
		return
	end
	
	-- Weapon slots (only when inventory closed)
	if not isInventoryOpen then
		if input.KeyCode == Enum.KeyCode.One then
			equipWeaponSlot(1)
		elseif input.KeyCode == Enum.KeyCode.Two then
			equipWeaponSlot(2)
		elseif input.KeyCode == Enum.KeyCode.Three then
			equipWeaponSlot(3)
		end
	end
end)

---------------------------------------
-- INITIALIZE
---------------------------------------
hudScreen = createHUD()
inventoryScreen, _ = createInventoryScreen()

-- Update weapon slots periodically
task.spawn(function()
	while true do
		task.wait(1)
		updateWeaponSlots()
	end
end)

-- Initial update
task.delay(1, function()
	updateWeaponSlots()
	print("[Client] Weapon slots updated")
end)

print("[Gridfall] Client initialized - WASD should work now!")