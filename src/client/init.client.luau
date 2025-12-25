-- Gridfall Client Main
-- Initializes all client-side systems

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer

-- Wait for shared modules
local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

-- Client modules
local GUICleanup = require(script.GUICleanup)
local CameraController = require(script.CameraController)
local InputController = require(script.InputController)
local UIController = require(script.UIController)

-- Wait for remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

-- Initialize systems (GUICleanup first to remove existing game UIs)
GUICleanup.Init()
CameraController.Init()
InputController.Init()
UIController.Init()

-- Disable default Roblox UI elements
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

print("[Gridfall] Client initialized successfully")