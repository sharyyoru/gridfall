-- Gridfall Camera Controller
-- Handles FPP/TPP camera transitions based on weapon state
-- Uses Roblox's default camera with offset adjustments for TPP

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local CameraController = {}

local player = Players.LocalPlayer

-- State
local currentMode: "FPP" | "TPP" = "TPP"
local isWeaponEquipped = false

-- Camera settings
local fppFOV = Constants.CAMERA.FPP_FOV
local tppFOV = Constants.CAMERA.TPP_FOV
local tppMinZoom = 8
local tppMaxZoom = 15
local fppMinZoom = 0.5
local fppMaxZoom = 0.5

function CameraController.GetCharacter(): Model?
	return player.Character
end

function CameraController.GetHumanoid(): Humanoid?
	local character = CameraController.GetCharacter()
	if character then
		return character:FindFirstChildOfClass("Humanoid")
	end
	return nil
end

function CameraController.SetMode(mode: "FPP" | "TPP")
	if currentMode == mode then return end
	
	currentMode = mode
	local camera = workspace.CurrentCamera
	
	if mode == "FPP" then
		-- First person mode - use default Roblox FPP
		player.CameraMinZoomDistance = fppMinZoom
		player.CameraMaxZoomDistance = fppMaxZoom
		CameraController.SetCharacterTransparency(1)
		
		local tweenInfo = TweenInfo.new(Constants.CAMERA.FPP_TRANSITION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(camera, tweenInfo, {FieldOfView = fppFOV})
		tween:Play()
	else
		-- Third person mode - use default Roblox TPP with zoom limits
		player.CameraMinZoomDistance = tppMinZoom
		player.CameraMaxZoomDistance = tppMaxZoom
		CameraController.SetCharacterTransparency(0)
		
		local tweenInfo = TweenInfo.new(Constants.CAMERA.TPP_TRANSITION_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(camera, tweenInfo, {FieldOfView = tppFOV})
		tween:Play()
	end
	
	print("[CameraController] Mode changed to " .. mode)
end

function CameraController.SetCharacterTransparency(transparency: number)
	local character = CameraController.GetCharacter()
	if not character then return end
	
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.LocalTransparencyModifier = transparency
		end
	end
end

function CameraController.OnWeaponEquipped()
	isWeaponEquipped = true
	CameraController.SetMode("FPP")
end

function CameraController.OnWeaponUnequipped()
	isWeaponEquipped = false
	CameraController.SetMode("TPP")
end

function CameraController.SetupRemoteListeners()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
	if not Remotes then return end
	
	local weaponEquipped = Remotes:FindFirstChild("WeaponEquipped")
	if weaponEquipped then
		weaponEquipped.OnClientEvent:Connect(function()
			CameraController.OnWeaponEquipped()
		end)
	end
	
	local weaponUnequipped = Remotes:FindFirstChild("WeaponUnequipped")
	if weaponUnequipped then
		weaponUnequipped.OnClientEvent:Connect(function()
			CameraController.OnWeaponUnequipped()
		end)
	end
end

function CameraController.OnCharacterAdded(character: Model)
	-- Wait for character to load
	character:WaitForChild("HumanoidRootPart")
	character:WaitForChild("Humanoid")
	
	-- Reset camera
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	
	-- Set initial mode (unarmed = TPP)
	task.wait(0.2)
	
	-- Force TPP zoom distance
	player.CameraMinZoomDistance = tppMinZoom
	player.CameraMaxZoomDistance = tppMaxZoom
	currentMode = "FPP" -- Set to FPP so SetMode will actually apply TPP
	CameraController.SetMode("TPP")
end

function CameraController.Init()
	-- Use Roblox's default camera system
	local camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Custom
	camera.FieldOfView = tppFOV
	
	-- Set initial zoom for TPP (force third person on start)
	player.CameraMinZoomDistance = tppMinZoom
	player.CameraMaxZoomDistance = tppMaxZoom
	player.CameraMode = Enum.CameraMode.Classic
	
	-- Force initial mode to TPP
	currentMode = "TPP"
	isWeaponEquipped = false
	
	-- Setup remote listeners
	CameraController.SetupRemoteListeners()
	
	-- Character added handling
	player.CharacterAdded:Connect(CameraController.OnCharacterAdded)
	if player.Character then
		CameraController.OnCharacterAdded(player.Character)
	end
	
	print("[CameraController] Initialized in TPP mode")
end

return CameraController
