-- Gridfall Client Main
-- Initializes all client-side systems

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- DISABLE ROBLOX DEFAULT UIS THAT INTERFERE
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false) -- This fixes Tab

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

-- Client modules
local CameraController = require(script.CameraController)
local InputController = require(script.InputController)

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

---------------------------------------
-- DIRECT WASD MOVEMENT (bypasses Blaster control interception)
---------------------------------------
local keysDown = {
	W = false,
	A = false,
	S = false,
	D = false,
}

local function getMovementDirection()
	local direction = Vector3.new(0, 0, 0)
	
	if keysDown.W then direction = direction + Vector3.new(0, 0, -1) end
	if keysDown.S then direction = direction + Vector3.new(0, 0, 1) end
	if keysDown.A then direction = direction + Vector3.new(-1, 0, 0) end
	if keysDown.D then direction = direction + Vector3.new(1, 0, 0) end
	
	if direction.Magnitude > 0 then
		direction = direction.Unit
	end
	
	return direction
end

local function setupDirectMovement()
	-- Track key states
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		
		if input.KeyCode == Enum.KeyCode.W then keysDown.W = true end
		if input.KeyCode == Enum.KeyCode.A then keysDown.A = true end
		if input.KeyCode == Enum.KeyCode.S then keysDown.S = true end
		if input.KeyCode == Enum.KeyCode.D then keysDown.D = true end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.W then keysDown.W = false end
		if input.KeyCode == Enum.KeyCode.A then keysDown.A = false end
		if input.KeyCode == Enum.KeyCode.S then keysDown.S = false end
		if input.KeyCode == Enum.KeyCode.D then keysDown.D = false end
	end)
	
	-- Apply movement every frame
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		if not character then return end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local hrp = character:FindFirstChild("HumanoidRootPart")
		
		if not humanoid or not hrp then return end
		
		local moveDir = getMovementDirection()
		
		if moveDir.Magnitude > 0 then
			-- Get camera direction for relative movement
			local camera = workspace.CurrentCamera
			local cameraDirection = camera.CFrame.LookVector
			local cameraRight = camera.CFrame.RightVector
			
			-- Flatten to horizontal plane
			cameraDirection = Vector3.new(cameraDirection.X, 0, cameraDirection.Z).Unit
			cameraRight = Vector3.new(cameraRight.X, 0, cameraRight.Z).Unit
			
			-- Calculate world movement direction
			local worldDirection = (cameraDirection * -moveDir.Z) + (cameraRight * moveDir.X)
			
			-- Move the humanoid
			humanoid:Move(worldDirection, false)
		else
			-- Stop movement
			humanoid:Move(Vector3.new(0, 0, 0), false)
		end
	end)
	
	print("[Client] Direct WASD movement system active")
end

-- Initialize direct movement
setupDirectMovement()

---------------------------------------
-- SIMPLE HUD (since StarterGui not syncing)
---------------------------------------
local function createSimpleHUD()
	local screen = Instance.new("ScreenGui")
	screen.Name = "GridfallHUD"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Parent = playerGui
	
	-- Crosshair
	local crosshair = Instance.new("Frame")
	crosshair.Name = "Crosshair"
	crosshair.Size = UDim2.new(0, 4, 0, 4)
	crosshair.Position = UDim2.new(0.5, -2, 0.5, -2)
	crosshair.BackgroundColor3 = Color3.new(1, 1, 1)
	crosshair.BorderSizePixel = 0
	crosshair.Parent = screen
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 2)
	corner.Parent = crosshair
	
	-- Simple weapon slot indicator at bottom
	local slotsFrame = Instance.new("Frame")
	slotsFrame.Name = "WeaponSlots"
	slotsFrame.Size = UDim2.new(0, 200, 0, 50)
	slotsFrame.Position = UDim2.new(0, 20, 1, -70)
	slotsFrame.BackgroundTransparency = 1
	slotsFrame.Parent = screen
	
	for i = 1, 3 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(0, 55, 0, 45)
		slot.Position = UDim2.new(0, (i-1) * 60, 0, 0)
		slot.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		slot.BackgroundTransparency = 0.3
		slot.Parent = slotsFrame
		
		local slotCorner = Instance.new("UICorner")
		slotCorner.CornerRadius = UDim.new(0, 6)
		slotCorner.Parent = slot
		
		local numLabel = Instance.new("TextLabel")
		numLabel.Size = UDim2.new(0, 15, 0, 15)
		numLabel.Position = UDim2.new(0, 3, 0, 3)
		numLabel.BackgroundColor3 = Color3.fromRGB(65, 185, 220)
		numLabel.Text = tostring(i)
		numLabel.TextColor3 = Color3.new(1, 1, 1)
		numLabel.TextSize = 10
		numLabel.Font = Enum.Font.GothamBold
		numLabel.Parent = slot
		
		local numCorner = Instance.new("UICorner")
		numCorner.CornerRadius = UDim.new(0, 3)
		numCorner.Parent = numLabel
	end
	
	-- Hint text
	local hint = Instance.new("TextLabel")
	hint.Name = "Hint"
	hint.Size = UDim2.new(0, 200, 0, 20)
	hint.Position = UDim2.new(0.5, -100, 1, -30)
	hint.BackgroundTransparency = 1
	hint.Text = "Press 1/2/3 for weapons | TAB for inventory"
	hint.TextColor3 = Color3.fromRGB(180, 180, 180)
	hint.TextSize = 12
	hint.Font = Enum.Font.Gotham
	hint.Parent = screen
	
	print("[Client] HUD created")
	return screen
end

---------------------------------------
-- INITIALIZE
---------------------------------------
CameraController.Init()
InputController.Init()

-- Create simple HUD
createSimpleHUD()

-- Disable default backpack
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

print("[Gridfall] Client initialized successfully")