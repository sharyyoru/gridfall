-- Gridfall HUD Component
-- Destiny 2-style heads-up display

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local HUD = {}

local player = Players.LocalPlayer
local hudScreen: ScreenGui? = nil

-- UI References
local weaponFrame: Frame?
local superFrame: Frame?
local ammoDisplay: Frame?
local healthBar: Frame?
local abilityBar: Frame?

-- Colors
local primaryColor = Constants.UI.PrimaryColor
local secondaryColor = Constants.UI.SecondaryColor
local bgColor = Constants.UI.BackgroundColor
local textColor = Constants.UI.TextColor

local function createCorner(parent: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 4)
	corner.Parent = parent
	return corner
end

local function createStroke(parent: GuiObject, color: Color3?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(80, 90, 100)
	stroke.Thickness = thickness or 1
	stroke.Transparency = 0.5
	stroke.Parent = parent
	return stroke
end

local function createGradient(parent: GuiObject, rotation: number?)
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = rotation or 90
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 180, 180)),
	})
	gradient.Parent = parent
	return gradient
end

function HUD.CreateWeaponSlots(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "WeaponSlots"
	container.Size = UDim2.new(0, 200, 0, 70)
	container.Position = UDim2.new(0, 30, 1, -90)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	-- Create 3 weapon slots (Kinetic, Energy, Power)
	local slotNames = {"Kinetic", "Energy", "Power"}
	local slotColors = {
		Color3.fromRGB(200, 200, 200), -- Kinetic - White/Gray
		primaryColor, -- Energy - Cyan
		Color3.fromRGB(120, 80, 180), -- Power - Purple
	}
	
	for i, slotName in ipairs(slotNames) do
		local slot = Instance.new("Frame")
		slot.Name = slotName .. "Slot"
		slot.Size = UDim2.new(0, 58, 0, 58)
		slot.Position = UDim2.new(0, (i - 1) * 65, 0, 0)
		slot.BackgroundColor3 = bgColor
		slot.BackgroundTransparency = 0.3
		slot.Parent = container
		createCorner(slot, 6)
		createStroke(slot, slotColors[i], 2)
		
		-- Slot number
		local numLabel = Instance.new("TextLabel")
		numLabel.Name = "SlotNumber"
		numLabel.Size = UDim2.new(0, 16, 0, 16)
		numLabel.Position = UDim2.new(0, 2, 0, 2)
		numLabel.BackgroundColor3 = slotColors[i]
		numLabel.BackgroundTransparency = 0.2
		numLabel.Text = tostring(i)
		numLabel.TextColor3 = Color3.new(1, 1, 1)
		numLabel.TextSize = 11
		numLabel.Font = Enum.Font.GothamBold
		numLabel.Parent = slot
		createCorner(numLabel, 3)
		
		-- Weapon icon placeholder
		local icon = Instance.new("ImageLabel")
		icon.Name = "WeaponIcon"
		icon.Size = UDim2.new(0, 40, 0, 40)
		icon.Position = UDim2.new(0.5, -20, 0.5, -15)
		icon.BackgroundTransparency = 1
		icon.Image = ""
		icon.ImageColor3 = Color3.new(1, 1, 1)
		icon.Parent = slot
	end
	
	return container
end

function HUD.CreateAmmoDisplay(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "AmmoDisplay"
	container.Size = UDim2.new(0, 140, 0, 60)
	container.Position = UDim2.new(1, -170, 1, -80)
	container.BackgroundColor3 = bgColor
	container.BackgroundTransparency = 0.4
	container.Parent = parent
	createCorner(container, 8)
	createStroke(container, primaryColor, 1)
	
	-- Current ammo (large)
	local currentAmmo = Instance.new("TextLabel")
	currentAmmo.Name = "CurrentAmmo"
	currentAmmo.Size = UDim2.new(0.6, 0, 0.7, 0)
	currentAmmo.Position = UDim2.new(0.05, 0, 0.1, 0)
	currentAmmo.BackgroundTransparency = 1
	currentAmmo.Text = "40"
	currentAmmo.TextColor3 = textColor
	currentAmmo.TextSize = 36
	currentAmmo.TextXAlignment = Enum.TextXAlignment.Left
	currentAmmo.Font = Enum.Font.GothamBold
	currentAmmo.Parent = container
	
	-- Reserve ammo
	local reserveAmmo = Instance.new("TextLabel")
	reserveAmmo.Name = "ReserveAmmo"
	reserveAmmo.Size = UDim2.new(0.35, 0, 0.4, 0)
	reserveAmmo.Position = UDim2.new(0.6, 0, 0.55, 0)
	reserveAmmo.BackgroundTransparency = 1
	reserveAmmo.Text = "/ 320"
	reserveAmmo.TextColor3 = Color3.fromRGB(180, 180, 180)
	reserveAmmo.TextSize = 16
	reserveAmmo.TextXAlignment = Enum.TextXAlignment.Left
	reserveAmmo.Font = Enum.Font.Gotham
	reserveAmmo.Parent = container
	
	-- Weapon type indicator
	local weaponType = Instance.new("TextLabel")
	weaponType.Name = "WeaponType"
	weaponType.Size = UDim2.new(0.9, 0, 0.25, 0)
	weaponType.Position = UDim2.new(0.05, 0, 0.02, 0)
	weaponType.BackgroundTransparency = 1
	weaponType.Text = "AUTO RIFLE"
	weaponType.TextColor3 = primaryColor
	weaponType.TextSize = 10
	weaponType.TextXAlignment = Enum.TextXAlignment.Left
	weaponType.Font = Enum.Font.GothamBold
	weaponType.Parent = container
	
	return container
end

function HUD.CreateSuperAbility(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "SuperAbility"
	container.Size = UDim2.new(0, 70, 0, 70)
	container.Position = UDim2.new(0.5, -35, 1, -90)
	container.BackgroundColor3 = bgColor
	container.BackgroundTransparency = 0.3
	container.Parent = parent
	createCorner(container, 35) -- Circular
	createStroke(container, secondaryColor, 3)
	
	-- Super icon
	local icon = Instance.new("ImageLabel")
	icon.Name = "SuperIcon"
	icon.Size = UDim2.new(0.6, 0, 0.6, 0)
	icon.Position = UDim2.new(0.2, 0, 0.2, 0)
	icon.BackgroundTransparency = 1
	icon.Image = "rbxassetid://6031075938" -- Diamond shape placeholder
	icon.ImageColor3 = secondaryColor
	icon.Parent = container
	
	-- Progress ring (simulated with frame)
	local progress = Instance.new("Frame")
	progress.Name = "ProgressRing"
	progress.Size = UDim2.new(1, 6, 1, 6)
	progress.Position = UDim2.new(0, -3, 0, -3)
	progress.BackgroundTransparency = 1
	progress.Parent = container
	
	return container
end

function HUD.CreateAbilities(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "Abilities"
	container.Size = UDim2.new(0, 180, 0, 45)
	container.Position = UDim2.new(0.5, -90, 1, -45)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	local abilityNames = {"Grenade", "Melee", "Class"}
	local abilityKeys = {"Q", "C", "V"}
	
	for i, name in ipairs(abilityNames) do
		local ability = Instance.new("Frame")
		ability.Name = name
		ability.Size = UDim2.new(0, 50, 0, 40)
		ability.Position = UDim2.new(0, (i - 1) * 60 + 5, 0, 0)
		ability.BackgroundColor3 = bgColor
		ability.BackgroundTransparency = 0.4
		ability.Parent = container
		createCorner(ability, 6)
		createStroke(ability, primaryColor, 1)
		
		-- Key binding
		local keyLabel = Instance.new("TextLabel")
		keyLabel.Name = "KeyBind"
		keyLabel.Size = UDim2.new(1, 0, 0.4, 0)
		keyLabel.Position = UDim2.new(0, 0, 0.55, 0)
		keyLabel.BackgroundTransparency = 1
		keyLabel.Text = abilityKeys[i]
		keyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		keyLabel.TextSize = 10
		keyLabel.Font = Enum.Font.GothamBold
		keyLabel.Parent = ability
	end
	
	return container
end

function HUD.CreateHealthBar(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "HealthBar"
	container.Size = UDim2.new(0, 200, 0, 8)
	container.Position = UDim2.new(0, 30, 1, -100)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BackgroundTransparency = 0.3
	container.Parent = parent
	createCorner(container, 4)
	
	-- Health fill
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.new(1, 0, 1, 0)
	fill.Position = UDim2.new(0, 0, 0, 0)
	fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	fill.Parent = container
	createCorner(fill, 4)
	createGradient(fill, 0)
	
	return container
end

function HUD.CreatePowerLevel(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "PowerLevel"
	container.Size = UDim2.new(0, 100, 0, 40)
	container.Position = UDim2.new(1, -130, 1, -140)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	-- Power icon (star)
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 20, 0, 20)
	icon.Position = UDim2.new(0, 0, 0.5, -10)
	icon.BackgroundTransparency = 1
	icon.Text = "✦"
	icon.TextColor3 = secondaryColor
	icon.TextSize = 18
	icon.Font = Enum.Font.GothamBold
	icon.Parent = container
	
	-- Power number
	local powerNum = Instance.new("TextLabel")
	powerNum.Name = "PowerNumber"
	powerNum.Size = UDim2.new(0, 70, 0, 30)
	powerNum.Position = UDim2.new(0, 25, 0.5, -15)
	powerNum.BackgroundTransparency = 1
	powerNum.Text = "1350"
	powerNum.TextColor3 = secondaryColor
	powerNum.TextSize = 24
	powerNum.TextXAlignment = Enum.TextXAlignment.Left
	powerNum.Font = Enum.Font.GothamBold
	powerNum.Parent = container
	
	return container
end

function HUD.CreateCrosshair(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "Crosshair"
	container.Size = UDim2.new(0, 30, 0, 30)
	container.Position = UDim2.new(0.5, -15, 0.5, -15)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	-- Center dot
	local dot = Instance.new("Frame")
	dot.Name = "Dot"
	dot.Size = UDim2.new(0, 4, 0, 4)
	dot.Position = UDim2.new(0.5, -2, 0.5, -2)
	dot.BackgroundColor3 = Color3.new(1, 1, 1)
	dot.Parent = container
	createCorner(dot, 2)
	
	-- Crosshair lines
	local directions = {
		{size = UDim2.new(0, 2, 0, 8), pos = UDim2.new(0.5, -1, 0, 2)}, -- Top
		{size = UDim2.new(0, 2, 0, 8), pos = UDim2.new(0.5, -1, 1, -10)}, -- Bottom
		{size = UDim2.new(0, 8, 0, 2), pos = UDim2.new(0, 2, 0.5, -1)}, -- Left
		{size = UDim2.new(0, 8, 0, 2), pos = UDim2.new(1, -10, 0.5, -1)}, -- Right
	}
	
	for i, dir in ipairs(directions) do
		local line = Instance.new("Frame")
		line.Name = "Line" .. i
		line.Size = dir.size
		line.Position = dir.pos
		line.BackgroundColor3 = Color3.new(1, 1, 1)
		line.BackgroundTransparency = 0.2
		line.Parent = container
	end
	
	return container
end

function HUD.Create(playerGui: PlayerGui): ScreenGui
	-- Create main screen
	local screen = Instance.new("ScreenGui")
	screen.Name = "HUDScreen"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui
	hudScreen = screen
	
	-- Main container
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(1, 0, 1, 0)
	main.BackgroundTransparency = 1
	main.Parent = screen
	
	-- Create HUD elements
	weaponFrame = HUD.CreateWeaponSlots(main)
	ammoDisplay = HUD.CreateAmmoDisplay(main)
	superFrame = HUD.CreateSuperAbility(main)
	abilityBar = HUD.CreateAbilities(main)
	healthBar = HUD.CreateHealthBar(main)
	HUD.CreatePowerLevel(main)
	HUD.CreateCrosshair(main)
	
	print("[HUD] Created Destiny-style HUD")
	return screen
end

return HUD
