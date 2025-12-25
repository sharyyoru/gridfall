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
-- MOVEMENT ENABLER - AGGRESSIVE VERSION
---------------------------------------
local function enableMovement(character)
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hrp = character:FindFirstChild("HumanoidRootPart")
	
	if not humanoid then 
		warn("[Client] No humanoid found!")
		return 
	end
	if not hrp then
		warn("[Client] No HumanoidRootPart found!")
		return
	end
	
	-- Unanchor HumanoidRootPart
	hrp.Anchored = false
	
	-- Unanchor ALL parts
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	
	-- FORCE movement properties
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	humanoid.JumpHeight = 7.2
	
	-- Enable all humanoid states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
	
	-- Disable states that freeze movement
	humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
	
	-- Force to running state
	local currentState = humanoid:GetState()
	if currentState == Enum.HumanoidStateType.PlatformStanding or
	   currentState == Enum.HumanoidStateType.Physics or
	   currentState == Enum.HumanoidStateType.Seated then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
end

local function setupCharacterMovement(character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	
	if not humanoid or not hrp then
		warn("[Client] Character missing Humanoid or HumanoidRootPart!")
		return
	end
	
	-- Initial enable after short delay
	task.wait(0.3)
	enableMovement(character)
	
	-- Log current state
	print("[Client] Movement enabled. Humanoid state: " .. tostring(humanoid:GetState()))
	print("[Client] WalkSpeed: " .. humanoid.WalkSpeed .. " | PlatformStand: " .. tostring(humanoid.PlatformStand))
	
	-- Keep enabling for 10 seconds to override other scripts
	task.spawn(function()
		for i = 1, 100 do
			task.wait(0.1)
			enableMovement(character)
		end
		print("[Client] Movement enabler finished 10 second cycle")
	end)
	
	-- Watch for state changes
	humanoid.StateChanged:Connect(function(old, new)
		print("[Client] State changed: " .. tostring(old) .. " -> " .. tostring(new))
		if new == Enum.HumanoidStateType.PlatformStanding or
		   new == Enum.HumanoidStateType.Physics or
		   new == Enum.HumanoidStateType.Seated then
			task.wait(0.05)
			enableMovement(character)
		end
	end)
	
	-- Watch for property changes
	humanoid:GetPropertyChangedSignal("PlatformStand"):Connect(function()
		if humanoid.PlatformStand then
			humanoid.PlatformStand = false
			print("[Client] Blocked PlatformStand = true")
		end
	end)
	
	humanoid:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
		if humanoid.WalkSpeed == 0 then
			humanoid.WalkSpeed = 16
			print("[Client] Blocked WalkSpeed = 0")
		end
	end)
end

-- Setup movement for current and future characters
if player.Character then
	task.spawn(function()
		setupCharacterMovement(player.Character)
	end)
end
player.CharacterAdded:Connect(function(char)
	task.spawn(function()
		setupCharacterMovement(char)
	end)
end)

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