-- Gridfall Character Scripts
-- SIMPLE movement enabler - runs on each character spawn

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = script.Parent.Parent

-- Wait for character to fully load
local humanoid = character:WaitForChild("Humanoid", 10)
local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 10)

if not humanoid or not humanoidRootPart then
	warn("[CharacterScript] Failed to find Humanoid or HumanoidRootPart")
	return
end

-- FORCE enable movement
local function enableMovement()
	-- Unanchor HumanoidRootPart
	humanoidRootPart.Anchored = false
	
	-- Reset humanoid state
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = 16
	humanoid.JumpPower = 50
	humanoid.JumpHeight = 7.2
	
	-- Force running state
	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
	-- Unanchor all parts
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
end

-- Run immediately
enableMovement()
print("[CharacterScript] Movement enabled for " .. player.Name)

-- Keep running every frame for 5 seconds to override any other scripts
local startTime = tick()
local connection
connection = RunService.Heartbeat:Connect(function()
	if tick() - startTime > 5 then
		connection:Disconnect()
		return
	end
	enableMovement()
end)

-- Also run when state changes to something bad
humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.PlatformStanding or 
	   new == Enum.HumanoidStateType.Seated or
	   new == Enum.HumanoidStateType.Physics then
		task.wait(0.1)
		enableMovement()
		print("[CharacterScript] Fixed bad state: " .. tostring(new))
	end
end)
