-- Gridfall Client Main
-- Complete rewrite with all fixes

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- DISABLE ALL ROBLOX DEFAULT UIS
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)

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
	if self._isAnyMenuOpen then
		-- Block weapon firing by sinking mouse input
		ContextActionService:BindActionAtPriority(
			"BlockWeaponFire",
			function() return Enum.ContextActionResult.Sink end,
			false,
			3000, -- High priority to override Blaster
			Enum.UserInputType.MouseButton1,
			Enum.UserInputType.MouseButton2
		)
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		ContextActionService:UnbindAction("BlockWeaponFire")
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
-- CAMERA SYSTEM (zoom-based, not ViewModel)
---------------------------------------
local TPP_MIN_ZOOM = 10
local TPP_MAX_ZOOM = 20
local FPP_MIN_ZOOM = 0.5
local FPP_MAX_ZOOM = 0.5
local currentCameraMode = "TPP"

local function setCameraMode(mode)
	currentCameraMode = mode
	if mode == "FPP" then
		player.CameraMinZoomDistance = FPP_MIN_ZOOM
		player.CameraMaxZoomDistance = FPP_MAX_ZOOM
		print("[Camera] Switched to FPP")
	else
		player.CameraMinZoomDistance = TPP_MIN_ZOOM
		player.CameraMaxZoomDistance = TPP_MAX_ZOOM
		print("[Camera] Switched to TPP")
	end
end

-- Continuously enforce camera mode (Blaster system keeps overriding)
RunService.RenderStepped:Connect(function()
	if currentCameraMode == "TPP" then
		if player.CameraMinZoomDistance < TPP_MIN_ZOOM then
			player.CameraMinZoomDistance = TPP_MIN_ZOOM
		end
		if player.CameraMaxZoomDistance < TPP_MAX_ZOOM then
			player.CameraMaxZoomDistance = TPP_MAX_ZOOM
		end
	end
end)

-- Start in TPP
task.spawn(function()
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	task.wait(1)
	setCameraMode("TPP")
	print("[Camera] Initial TPP mode set")
end)

---------------------------------------
-- MOVEMENT SYSTEM (BodyVelocity - proven to work)
---------------------------------------
local keysDown = { W = false, A = false, S = false, D = false, Space = false }
local WALK_SPEED = 20
local currentMover = nil

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	-- ALWAYS track movement keys regardless of gameProcessed
	if input.KeyCode == Enum.KeyCode.W then keysDown.W = true end
	if input.KeyCode == Enum.KeyCode.A then keysDown.A = true end
	if input.KeyCode == Enum.KeyCode.S then keysDown.S = true end
	if input.KeyCode == Enum.KeyCode.D then keysDown.D = true end
	if input.KeyCode == Enum.KeyCode.Space then keysDown.Space = true end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.W then keysDown.W = false end
	if input.KeyCode == Enum.KeyCode.A then keysDown.A = false end
	if input.KeyCode == Enum.KeyCode.S then keysDown.S = false end
	if input.KeyCode == Enum.KeyCode.D then keysDown.D = false end
	if input.KeyCode == Enum.KeyCode.Space then keysDown.Space = false end
end)

local function setupMovement(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not hrp then return end
	
	-- Remove old mover if exists
	local oldMover = hrp:FindFirstChild("GridfallMover")
	if oldMover then oldMover:Destroy() end
	
	-- Create BodyVelocity for movement
	local mover = Instance.new("BodyVelocity")
	mover.Name = "GridfallMover"
	mover.MaxForce = Vector3.new(50000, 0, 50000) -- Horizontal only, let physics handle Y
	mover.Velocity = Vector3.new(0, 0, 0)
	mover.P = 5000 -- Lower P for smoother feel
	mover.Parent = hrp
	currentMover = mover
	
	print("[Movement] BodyVelocity created")
end

-- Setup for characters
if player.Character then
	task.spawn(function() setupMovement(player.Character) end)
end
player.CharacterAdded:Connect(function(char)
	task.spawn(function() setupMovement(char) end)
end)

-- Movement update loop
RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return end
	
	local mover = hrp:FindFirstChild("GridfallMover")
	if not mover then return end
	
	-- Calculate movement direction
	local direction = Vector3.new(0, 0, 0)
	if keysDown.W then direction = direction + Vector3.new(0, 0, -1) end
	if keysDown.S then direction = direction + Vector3.new(0, 0, 1) end
	if keysDown.A then direction = direction + Vector3.new(-1, 0, 0) end
	if keysDown.D then direction = direction + Vector3.new(1, 0, 0) end
	
	if direction.Magnitude > 0 then
		direction = direction.Unit
		local camera = workspace.CurrentCamera
		local camLook = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		local camRight = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
		
		if camLook.Magnitude > 0 then camLook = camLook.Unit end
		if camRight.Magnitude > 0 then camRight = camRight.Unit end
		
		local worldDir = (camLook * -direction.Z) + (camRight * direction.X)
		mover.Velocity = worldDir * WALK_SPEED
	else
		mover.Velocity = Vector3.new(0, 0, 0)
	end
	
	-- Jump - use humanoid's natural jump
	if keysDown.Space and humanoid.FloorMaterial ~= Enum.Material.Air then
		humanoid.Jump = true
	end
end)

print("[Client] BodyVelocity movement system active")

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
	
	-- Crosshair
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0, 4, 0, 4)
	crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
	crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
	crosshair.BorderSizePixel = 0
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
				updateInventoryScreen()
				MenuManager:OpenMenu("Inventory")
			else
				MenuManager:CloseMenu("Inventory")
			end
		end
	end
	
	print("[Inventory] " .. (isInventoryOpen and "OPENED" or "CLOSED"))
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