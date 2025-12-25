-- Gridfall Inventory Component
-- Destiny 2-style inventory and equipment screen (Tab to open)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local Inventory = {}

local player = Players.LocalPlayer
local inventoryScreen: ScreenGui? = nil

-- Colors
local primaryColor = Constants.UI.PrimaryColor
local secondaryColor = Constants.UI.SecondaryColor
local bgColor = Constants.UI.BackgroundColor
local textColor = Constants.UI.TextColor
local rarityColors = Constants.UI.RarityColors

local function createCorner(parent: GuiObject, radius: number?)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 4)
	corner.Parent = parent
	return corner
end

local function createStroke(parent: GuiObject, color: Color3?, thickness: number?)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Color3.fromRGB(60, 70, 80)
	stroke.Thickness = thickness or 1
	stroke.Transparency = 0.3
	stroke.Parent = parent
	return stroke
end

local function createShadow(parent: GuiObject)
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, 20, 1, 20)
	shadow.Position = UDim2.new(0, -10, 0, -10)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://5554236805"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.6
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(23, 23, 277, 277)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

function Inventory.CreateHeader(parent: Frame): Frame
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, 80)
	header.Position = UDim2.new(0, 0, 0, 0)
	header.BackgroundTransparency = 1
	header.Parent = parent
	
	-- Player name
	local playerName = Instance.new("TextLabel")
	playerName.Name = "PlayerName"
	playerName.Size = UDim2.new(0, 300, 0, 35)
	playerName.Position = UDim2.new(0, 40, 0, 15)
	playerName.BackgroundTransparency = 1
	playerName.Text = string.upper(player.Name)
	playerName.TextColor3 = textColor
	playerName.TextSize = 28
	playerName.TextXAlignment = Enum.TextXAlignment.Left
	playerName.Font = Enum.Font.GothamBold
	playerName.Parent = header
	
	-- Level info
	local levelInfo = Instance.new("TextLabel")
	levelInfo.Name = "LevelInfo"
	levelInfo.Size = UDim2.new(0, 200, 0, 20)
	levelInfo.Position = UDim2.new(0, 40, 0, 48)
	levelInfo.BackgroundTransparency = 1
	levelInfo.Text = "// LEVEL 50 ✦1350"
	levelInfo.TextColor3 = Color3.fromRGB(150, 150, 150)
	levelInfo.TextSize = 14
	levelInfo.TextXAlignment = Enum.TextXAlignment.Left
	levelInfo.Font = Enum.Font.Gotham
	levelInfo.Parent = header
	
	-- Tab buttons (Character, Inventory, Settings)
	local tabs = Instance.new("Frame")
	tabs.Name = "Tabs"
	tabs.Size = UDim2.new(0, 400, 0, 30)
	tabs.Position = UDim2.new(0.5, -50, 0, 25)
	tabs.BackgroundTransparency = 1
	tabs.Parent = header
	
	local tabNames = {"CHARACTER", "INVENTORY", "SETTINGS"}
	for i, name in ipairs(tabNames) do
		local tab = Instance.new("TextButton")
		tab.Name = name
		tab.Size = UDim2.new(0, 120, 0, 30)
		tab.Position = UDim2.new(0, (i - 1) * 130, 0, 0)
		tab.BackgroundTransparency = 1
		tab.Text = name
		tab.TextColor3 = i == 1 and textColor or Color3.fromRGB(120, 120, 120)
		tab.TextSize = 14
		tab.Font = Enum.Font.GothamBold
		tab.Parent = tabs
		
		if i == 1 then
			local underline = Instance.new("Frame")
			underline.Name = "Underline"
			underline.Size = UDim2.new(1, 0, 0, 2)
			underline.Position = UDim2.new(0, 0, 1, 2)
			underline.BackgroundColor3 = textColor
			underline.Parent = tab
		end
	end
	
	-- Currencies
	local currencies = Instance.new("Frame")
	currencies.Name = "Currencies"
	currencies.Size = UDim2.new(0, 250, 0, 25)
	currencies.Position = UDim2.new(1, -290, 0, 25)
	currencies.BackgroundTransparency = 1
	currencies.Parent = header
	
	local currencyTypes = {
		{icon = "●", color = Color3.fromRGB(200, 200, 200), value = "000000"},
		{icon = "◆", color = primaryColor, value = "000"},
		{icon = "★", color = secondaryColor, value = "000"},
	}
	
	for i, curr in ipairs(currencyTypes) do
		local currFrame = Instance.new("Frame")
		currFrame.Size = UDim2.new(0, 75, 0, 20)
		currFrame.Position = UDim2.new(0, (i - 1) * 80, 0, 0)
		currFrame.BackgroundTransparency = 1
		currFrame.Parent = currencies
		
		local icon = Instance.new("TextLabel")
		icon.Size = UDim2.new(0, 15, 0, 20)
		icon.BackgroundTransparency = 1
		icon.Text = curr.icon
		icon.TextColor3 = curr.color
		icon.TextSize = 12
		icon.Font = Enum.Font.GothamBold
		icon.Parent = currFrame
		
		local value = Instance.new("TextLabel")
		value.Size = UDim2.new(0, 55, 0, 20)
		value.Position = UDim2.new(0, 18, 0, 0)
		value.BackgroundTransparency = 1
		value.Text = curr.value
		value.TextColor3 = textColor
		value.TextSize = 12
		value.TextXAlignment = Enum.TextXAlignment.Left
		value.Font = Enum.Font.Gotham
		value.Parent = currFrame
	end
	
	return header
end

function Inventory.CreateCharacterPreview(parent: Frame): Frame
	local preview = Instance.new("Frame")
	preview.Name = "CharacterPreview"
	preview.Size = UDim2.new(0, 350, 0, 500)
	preview.Position = UDim2.new(0.5, -175, 0.5, -220)
	preview.BackgroundColor3 = Color3.fromRGB(15, 18, 25)
	preview.BackgroundTransparency = 0.3
	preview.Parent = parent
	createCorner(preview, 8)
	createStroke(preview, Color3.fromRGB(40, 50, 60), 1)
	
	-- Class emblem
	local emblem = Instance.new("Frame")
	emblem.Name = "ClassEmblem"
	emblem.Size = UDim2.new(0, 80, 0, 80)
	emblem.Position = UDim2.new(0.5, -40, 0, 30)
	emblem.BackgroundColor3 = secondaryColor
	emblem.BackgroundTransparency = 0.7
	emblem.Parent = preview
	createCorner(emblem, 40)
	
	local emblemIcon = Instance.new("TextLabel")
	emblemIcon.Size = UDim2.new(1, 0, 1, 0)
	emblemIcon.BackgroundTransparency = 1
	emblemIcon.Text = "⬡"
	emblemIcon.TextColor3 = secondaryColor
	emblemIcon.TextSize = 40
	emblemIcon.Font = Enum.Font.GothamBold
	emblemIcon.Parent = emblem
	
	-- ViewportFrame for character model
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "CharacterViewport"
	viewport.Size = UDim2.new(0.9, 0, 0.65, 0)
	viewport.Position = UDim2.new(0.05, 0, 0.2, 0)
	viewport.BackgroundTransparency = 1
	viewport.Parent = preview
	
	-- Stats display
	local stats = Instance.new("Frame")
	stats.Name = "Stats"
	stats.Size = UDim2.new(0, 150, 0, 100)
	stats.Position = UDim2.new(1, 20, 0, 130)
	stats.BackgroundTransparency = 1
	stats.Parent = preview
	
	-- Power level
	local powerFrame = Instance.new("Frame")
	powerFrame.Name = "Power"
	powerFrame.Size = UDim2.new(1, 0, 0, 30)
	powerFrame.BackgroundTransparency = 1
	powerFrame.Parent = stats
	
	local powerIcon = Instance.new("TextLabel")
	powerIcon.Size = UDim2.new(0, 20, 0, 30)
	powerIcon.BackgroundTransparency = 1
	powerIcon.Text = "✦"
	powerIcon.TextColor3 = secondaryColor
	powerIcon.TextSize = 16
	powerIcon.Font = Enum.Font.GothamBold
	powerIcon.Parent = powerFrame
	
	local powerLabel = Instance.new("TextLabel")
	powerLabel.Name = "PowerLabel"
	powerLabel.Size = UDim2.new(0, 50, 0, 15)
	powerLabel.Position = UDim2.new(0, 22, 0, 0)
	powerLabel.BackgroundTransparency = 1
	powerLabel.Text = "POWER"
	powerLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	powerLabel.TextSize = 10
	powerLabel.TextXAlignment = Enum.TextXAlignment.Left
	powerLabel.Font = Enum.Font.Gotham
	powerLabel.Parent = powerFrame
	
	local powerValue = Instance.new("TextLabel")
	powerValue.Name = "PowerValue"
	powerValue.Size = UDim2.new(0, 60, 0, 20)
	powerValue.Position = UDim2.new(0, 22, 0, 12)
	powerValue.BackgroundTransparency = 1
	powerValue.Text = "1350"
	powerValue.TextColor3 = secondaryColor
	powerValue.TextSize = 18
	powerValue.TextXAlignment = Enum.TextXAlignment.Left
	powerValue.Font = Enum.Font.GothamBold
	powerValue.Parent = powerFrame
	
	-- Stat bars
	local statTypes = {
		{name = "Mobility", icon = "⚡", value = 99},
		{name = "Resilience", icon = "🛡", value = 99},
		{name = "Recovery", icon = "♥", value = 99},
	}
	
	for i, stat in ipairs(statTypes) do
		local statFrame = Instance.new("Frame")
		statFrame.Name = stat.name
		statFrame.Size = UDim2.new(1, 0, 0, 20)
		statFrame.Position = UDim2.new(0, 0, 0, 35 + (i * 22))
		statFrame.BackgroundTransparency = 1
		statFrame.Parent = stats
		
		local statLabel = Instance.new("TextLabel")
		statLabel.Size = UDim2.new(0, 80, 0, 15)
		statLabel.BackgroundTransparency = 1
		statLabel.Text = stat.name .. " " .. stat.icon
		statLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
		statLabel.TextSize = 11
		statLabel.TextXAlignment = Enum.TextXAlignment.Left
		statLabel.Font = Enum.Font.Gotham
		statLabel.Parent = statFrame
		
		local statValue = Instance.new("TextLabel")
		statValue.Size = UDim2.new(0, 30, 0, 15)
		statValue.Position = UDim2.new(1, -30, 0, 0)
		statValue.BackgroundTransparency = 1
		statValue.Text = tostring(stat.value)
		statValue.TextColor3 = textColor
		statValue.TextSize = 12
		statValue.TextXAlignment = Enum.TextXAlignment.Right
		statValue.Font = Enum.Font.GothamBold
		statValue.Parent = statFrame
	end
	
	return preview
end

function Inventory.CreateItemSlot(parent: Frame, slotType: string, position: UDim2, size: UDim2?): Frame
	local slot = Instance.new("Frame")
	slot.Name = slotType .. "Slot"
	slot.Size = size or UDim2.new(0, 70, 0, 70)
	slot.Position = position
	slot.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
	slot.BackgroundTransparency = 0.2
	slot.Parent = parent
	createCorner(slot, 6)
	createStroke(slot, Color3.fromRGB(60, 70, 80), 1)
	
	-- Rarity bar (bottom)
	local rarityBar = Instance.new("Frame")
	rarityBar.Name = "RarityBar"
	rarityBar.Size = UDim2.new(0.8, 0, 0, 3)
	rarityBar.Position = UDim2.new(0.1, 0, 1, -8)
	rarityBar.BackgroundColor3 = rarityColors.Legendary
	rarityBar.Parent = slot
	createCorner(rarityBar, 2)
	
	-- Item icon
	local icon = Instance.new("ImageLabel")
	icon.Name = "ItemIcon"
	icon.Size = UDim2.new(0.75, 0, 0.75, 0)
	icon.Position = UDim2.new(0.125, 0, 0.08, 0)
	icon.BackgroundTransparency = 1
	icon.Image = ""
	icon.Parent = slot
	
	-- Power level badge
	local powerBadge = Instance.new("TextLabel")
	powerBadge.Name = "PowerBadge"
	powerBadge.Size = UDim2.new(0, 30, 0, 14)
	powerBadge.Position = UDim2.new(0.5, -15, 0, 2)
	powerBadge.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	powerBadge.BackgroundTransparency = 0.5
	powerBadge.Text = "1350"
	powerBadge.TextColor3 = textColor
	powerBadge.TextSize = 9
	powerBadge.Font = Enum.Font.GothamBold
	powerBadge.Parent = slot
	createCorner(powerBadge, 3)
	
	-- Hover effect
	local hoverFrame = Instance.new("Frame")
	hoverFrame.Name = "Hover"
	hoverFrame.Size = UDim2.new(1, 4, 1, 4)
	hoverFrame.Position = UDim2.new(0, -2, 0, -2)
	hoverFrame.BackgroundTransparency = 1
	hoverFrame.Visible = false
	hoverFrame.Parent = slot
	createCorner(hoverFrame, 8)
	createStroke(hoverFrame, primaryColor, 2)
	
	-- Button for interaction
	local button = Instance.new("TextButton")
	button.Name = "Button"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = slot
	
	button.MouseEnter:Connect(function()
		hoverFrame.Visible = true
	end)
	
	button.MouseLeave:Connect(function()
		hoverFrame.Visible = false
	end)
	
	return slot
end

function Inventory.CreateWeaponSlots(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "WeaponSlots"
	container.Size = UDim2.new(0, 100, 0, 250)
	container.Position = UDim2.new(0, 40, 0.5, -95)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	-- Weapon slot labels
	local slotTypes = {"Kinetic", "Energy", "Power"}
	
	for i, slotType in ipairs(slotTypes) do
		local yPos = (i - 1) * 85
		Inventory.CreateItemSlot(container, slotType, UDim2.new(0, 0, 0, yPos), UDim2.new(0, 75, 0, 75))
		
		-- Slot label
		local label = Instance.new("TextLabel")
		label.Name = slotType .. "Label"
		label.Size = UDim2.new(0, 75, 0, 12)
		label.Position = UDim2.new(0, 0, 0, yPos + 77)
		label.BackgroundTransparency = 1
		label.Text = string.upper(slotType)
		label.TextColor3 = Color3.fromRGB(100, 100, 100)
		label.TextSize = 9
		label.Font = Enum.Font.GothamBold
		label.Parent = container
	end
	
	return container
end

function Inventory.CreateArmorSlots(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "ArmorSlots"
	container.Size = UDim2.new(0, 100, 0, 400)
	container.Position = UDim2.new(1, -140, 0.5, -170)
	container.BackgroundTransparency = 1
	container.Parent = parent
	
	-- Armor slot types
	local slotTypes = {"Helmet", "Arms", "Chest", "Legs", "Class"}
	
	for i, slotType in ipairs(slotTypes) do
		local yPos = (i - 1) * 78
		Inventory.CreateItemSlot(container, slotType, UDim2.new(0, 0, 0, yPos), UDim2.new(0, 70, 0, 70))
	end
	
	return container
end

function Inventory.CreateInventoryGrid(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "InventoryGrid"
	container.Size = UDim2.new(0, 320, 0, 400)
	container.Position = UDim2.new(0, 40, 0, 100)
	container.BackgroundColor3 = Color3.fromRGB(18, 22, 30)
	container.BackgroundTransparency = 0.3
	container.Parent = parent
	createCorner(container, 8)
	
	-- Section label
	local label = Instance.new("TextLabel")
	label.Name = "SectionLabel"
	label.Size = UDim2.new(1, 0, 0, 25)
	label.Position = UDim2.new(0, 0, 0, -30)
	label.BackgroundTransparency = 1
	label.Text = "/ENERGY"
	label.TextColor3 = Color3.fromRGB(120, 120, 120)
	label.TextSize = 12
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Font = Enum.Font.GothamBold
	label.Parent = container
	
	-- Grid layout
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.new(0, 65, 0, 65)
	grid.CellPadding = UDim2.new(0, 8, 0, 8)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = container
	
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.Parent = container
	
	-- Create 9 inventory slots
	for i = 1, 9 do
		local slot = Instance.new("Frame")
		slot.Name = "Slot" .. i
		slot.Size = UDim2.new(0, 65, 0, 65)
		slot.BackgroundColor3 = Color3.fromRGB(30, 35, 45)
		slot.BackgroundTransparency = 0.3
		slot.LayoutOrder = i
		slot.Parent = container
		createCorner(slot, 4)
		createStroke(slot, Color3.fromRGB(50, 55, 65), 1)
		
		-- Rarity indicator
		local rarity = Instance.new("Frame")
		rarity.Name = "Rarity"
		rarity.Size = UDim2.new(0.7, 0, 0, 2)
		rarity.Position = UDim2.new(0.15, 0, 1, -6)
		rarity.BackgroundColor3 = rarityColors.Legendary
		rarity.Parent = slot
		createCorner(rarity, 1)
	end
	
	return container
end

function Inventory.CreateDismissButton(parent: Frame): TextButton
	local button = Instance.new("TextButton")
	button.Name = "DismissButton"
	button.Size = UDim2.new(0, 120, 0, 30)
	button.Position = UDim2.new(0.5, -60, 1, -50)
	button.BackgroundTransparency = 1
	button.Text = "○ Dismiss"
	button.TextColor3 = Color3.fromRGB(150, 150, 150)
	button.TextSize = 14
	button.Font = Enum.Font.Gotham
	button.Parent = parent
	
	return button
end

function Inventory.Create(playerGui: PlayerGui): ScreenGui
	-- Create main screen
	local screen = Instance.new("ScreenGui")
	screen.Name = "InventoryScreen"
	screen.ResetOnSpawn = false
	screen.IgnoreGuiInset = true
	screen.Enabled = false -- Start hidden
	screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screen.Parent = playerGui
	inventoryScreen = screen
	
	-- Background blur effect
	local blur = Instance.new("Frame")
	blur.Name = "Blur"
	blur.Size = UDim2.new(1, 0, 1, 0)
	blur.BackgroundColor3 = Color3.fromRGB(5, 8, 15)
	blur.BackgroundTransparency = 0.15
	blur.Parent = screen
	
	-- Main container
	local main = Instance.new("Frame")
	main.Name = "Main"
	main.Size = UDim2.new(1, 0, 1, 0)
	main.BackgroundTransparency = 1
	main.Parent = screen
	
	-- Create all sections
	Inventory.CreateHeader(main)
	Inventory.CreateCharacterPreview(main)
	Inventory.CreateWeaponSlots(main)
	Inventory.CreateArmorSlots(main)
	Inventory.CreateInventoryGrid(main)
	
	local dismissBtn = Inventory.CreateDismissButton(main)
	dismissBtn.MouseButton1Click:Connect(function()
		screen.Enabled = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end)
	
	print("[Inventory] Created Destiny-style inventory UI")
	return screen
end

return Inventory
