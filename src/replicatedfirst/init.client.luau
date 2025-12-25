-- Gridfall ReplicatedFirst
-- Loading screen and early initialization

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remove default loading screen
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- Create loading screen
local loadingScreen = Instance.new("ScreenGui")
loadingScreen.Name = "LoadingScreen"
loadingScreen.IgnoreGuiInset = true
loadingScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
loadingScreen.Parent = playerGui

-- Background
local background = Instance.new("Frame")
background.Name = "Background"
background.Size = UDim2.new(1, 0, 1, 0)
background.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
background.BorderSizePixel = 0
background.Parent = loadingScreen

-- Logo/Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 400, 0, 80)
title.Position = UDim2.new(0.5, -200, 0.4, -40)
title.BackgroundTransparency = 1
title.Text = "GRIDFALL"
title.TextColor3 = Color3.fromRGB(240, 240, 240)
title.TextSize = 60
title.Font = Enum.Font.GothamBold
title.Parent = background

-- Subtitle
local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(0, 400, 0, 30)
subtitle.Position = UDim2.new(0.5, -200, 0.4, 40)
subtitle.BackgroundTransparency = 1
subtitle.Text = "PREPARING YOUR ARSENAL..."
subtitle.TextColor3 = Color3.fromRGB(65, 185, 220)
subtitle.TextSize = 14
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = background

-- Loading bar background
local loadingBarBg = Instance.new("Frame")
loadingBarBg.Name = "LoadingBarBg"
loadingBarBg.Size = UDim2.new(0, 300, 0, 4)
loadingBarBg.Position = UDim2.new(0.5, -150, 0.55, 0)
loadingBarBg.BackgroundColor3 = Color3.fromRGB(40, 45, 55)
loadingBarBg.BorderSizePixel = 0
loadingBarBg.Parent = background

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 2)
corner.Parent = loadingBarBg

-- Loading bar fill
local loadingBarFill = Instance.new("Frame")
loadingBarFill.Name = "Fill"
loadingBarFill.Size = UDim2.new(0, 0, 1, 0)
loadingBarFill.BackgroundColor3 = Color3.fromRGB(65, 185, 220)
loadingBarFill.BorderSizePixel = 0
loadingBarFill.Parent = loadingBarBg

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(0, 2)
fillCorner.Parent = loadingBarFill

-- Animate loading bar
local function animateLoading()
	local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(loadingBarFill, tweenInfo, {Size = UDim2.new(1, 0, 1, 0)})
	tween:Play()
	tween.Completed:Wait()
end

-- Wait for game to load
task.spawn(function()
	-- Animate loading
	animateLoading()
	
	-- Wait for character
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	
	-- Additional wait for smooth transition
	task.wait(0.5)
	
	-- Fade out
	local fadeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fadeTween = TweenService:Create(background, fadeInfo, {BackgroundTransparency = 1})
	local titleFade = TweenService:Create(title, fadeInfo, {TextTransparency = 1})
	local subtitleFade = TweenService:Create(subtitle, fadeInfo, {TextTransparency = 1})
	local barFade = TweenService:Create(loadingBarBg, fadeInfo, {BackgroundTransparency = 1})
	local fillFade = TweenService:Create(loadingBarFill, fadeInfo, {BackgroundTransparency = 1})
	
	fadeTween:Play()
	titleFade:Play()
	subtitleFade:Play()
	barFade:Play()
	fillFade:Play()
	
	fadeTween.Completed:Wait()
	loadingScreen:Destroy()
end)

print("[ReplicatedFirst] Loading screen initialized")
