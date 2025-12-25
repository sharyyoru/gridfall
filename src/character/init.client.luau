-- Gridfall Character Scripts
-- AGGRESSIVE movement enabler that enables Roblox default controls

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local character = script.Parent.Parent

local humanoid = character:WaitForChild("Humanoid", 10)
local hrp = character:WaitForChild("HumanoidRootPart", 10)

if not humanoid or not hrp then
	warn("[CharacterScript] Failed to find Humanoid or HumanoidRootPart")
	return
end

local WALK_SPEED = 18
local JUMP_POWER = 60

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
	hrp.Anchored = false
	humanoid.PlatformStand = false
	humanoid.Sit = false
	humanoid.AutoRotate = true
	humanoid.WalkSpeed = WALK_SPEED
	humanoid.JumpPower = JUMP_POWER
	humanoid.JumpHeight = 0 -- Use JumpPower
	
	-- Enable all humanoid states
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.RunningNoPhysics, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, true)
	humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, true)
	
	if humanoid:GetState() ~= Enum.HumanoidStateType.Running then
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
	end
	
	-- Unanchor all parts
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "Handle" then
			part.Anchored = false
		end
	end
end

-- Run setup
setupCharacter()
task.delay(0.5, enableDefaultControls)
print("[CharacterScript] Character setup complete - WalkSpeed:", WALK_SPEED, "JumpPower:", JUMP_POWER)

-- Continuously enforce for first 10 seconds
local startTime = tick()
RunService.Heartbeat:Connect(function()
	if tick() - startTime < 10 then
		humanoid.WalkSpeed = WALK_SPEED
		humanoid.JumpPower = JUMP_POWER
		humanoid.PlatformStand = false
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
