-- Gridfall Character Scripts
-- Use PURE Roblox default movement - no custom physics

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local player = Players.LocalPlayer

-- Wait for character (script is nested in CharacterScripts folder inside character)
local character = player.Character or player.CharacterAdded:Wait()

-- Wait for humanoid with retry
local humanoid, hrp
for i = 1, 20 do
	humanoid = character:FindFirstChildOfClass("Humanoid")
	hrp = character:FindFirstChild("HumanoidRootPart")
	if humanoid and hrp then break end
	task.wait(0.25)
end

if not humanoid or not hrp then
	warn("[CharacterScript] Failed to find Humanoid or HumanoidRootPart after 5s")
	return
end

local WALK_SPEED = Constants.CHARACTER.DefaultWalkSpeed
local JUMP_POWER = Constants.CHARACTER.DefaultJumpPower

-- Enable Roblox's default PlayerModule controls
local function enableDefaultControls()
	local PlayerModule = player.PlayerScripts:FindFirstChild("PlayerModule")
	if PlayerModule then
		local ControlModule = require(PlayerModule):GetControls()
		if ControlModule then
			ControlModule:Enable(true)
			print("[CharacterScript] Default controls enabled via PlayerModule")
		end
	end
end

local function setupCharacter()
	-- ONLY set basic humanoid properties - NO custom physics
	hrp.Anchored = false
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.JumpPower = JUMP_POWER
	humanoid.JumpHeight = 0 -- Use JumpPower
	humanoid.UseJumpPower = true -- Ensure JumpPower is used
	
	-- IMPORTANT: Enable RunningNoPhysics to prevent floating
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true) -- Enable this!
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Swimming, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, true)
	
	-- Force character into proper physics state
	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
	
	-- Ensure gravity is working
	if workspace.Gravity == 0 then
		workspace.Gravity = 196.2 -- Standard Roblox gravity
	end
	
	-- Just unanchor parts - NO custom physics
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Handle" then
			part.Anchored = false
			part.CanCollide = true
		end
	end
end

-- Run setup
setupCharacter()
task.delay(0.5, enableDefaultControls)
print("[CharacterScript] Character setup complete - WalkSpeed:", WALK_SPEED, "JumpPower:", JUMP_POWER)

-- Continuously remove problematic physics objects
local function cleanupPhysicsObjects()
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then return end
	
	-- Remove any physics constraints that could cause floating
	local problematicObjects = {"BodyVelocity", "BodyForce", "BodyGyro", "BodyPosition", "AlignPosition", "AlignOrientation"}
	
	for _, objName in ipairs(problematicObjects) do
		local obj = hrp:FindFirstChild(objName)
		if obj then
			obj:Destroy()
			print("[CharacterScript] Removed problematic physics object:", objName)
		end
	end
	
	-- Check all parts for these objects
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			for _, objName in ipairs(problematicObjects) do
				local obj = part:FindFirstChild(objName)
				if obj then
					obj:Destroy()
					print("[CharacterScript] Removed physics object from", part.Name, ":", objName)
				end
			end
		end
	end
end

-- Run cleanup every 2 seconds for first 30 seconds
local cleanupCount = 0
task.spawn(function()
	while cleanupCount < 15 do -- 15 * 2 = 30 seconds
		task.wait(2)
		cleanupPhysicsObjects()
		
		-- Also ensure gravity is working
		if workspace.Gravity == 0 or workspace.Gravity < 100 then
			workspace.Gravity = 196.2
			print("[CharacterScript] Fixed gravity")
		end
		
		cleanupCount += 1
	end
	print("[CharacterScript] Physics cleanup completed")
end)

-- Force gravity to apply to character
task.spawn(function()
	while true do
		task.wait(0.5)
		local character = player.Character
		if character then
			local hrp = character:FindFirstChild("HumanoidRootPart")
			if hrp and hrp.Position.Y > 100 then -- If character is way too high
				-- Apply gentle downward force
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
					-- Let gravity do its job, but ensure it's not zero
					if workspace.Gravity == 0 then
						workspace.Gravity = 196.2
					end
				end
			end
		end
	end
end)

-- Fix bad states
humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.PlatformStanding or 
	   new == Enum.HumanoidStateType.Seated or
	   new == Enum.HumanoidStateType.Physics then
		task.wait(0.1)
		setupCharacter()
		print("[CharacterScript] Fixed bad state:", new)
	end
end)
