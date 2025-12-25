-- Gridfall GUI Cleanup
-- Destroys existing game GUIs on client side

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local GUICleanup = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Names of OUR GUIs to keep
local PROTECTED_GUI_NAMES = {
	["GridfallUI"] = true,
	["HUDScreen"] = true,
	["InventoryScreen"] = true,
	["LoadingScreen"] = true,
}

function GUICleanup.DestroyExistingGuis()
	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and not PROTECTED_GUI_NAMES[gui.Name] then
			-- Check if it looks like a game mode GUI (has timer, score, etc.)
			local hasTimer = gui:FindFirstChild("Timer", true) or gui:FindFirstChild("TimerLabel", true)
			local hasScore = gui:FindFirstChild("Score", true) or gui:FindFirstChild("ScoreLabel", true)
			local hasTeam = gui:FindFirstChild("Team", true) or gui:FindFirstChild("TeamLabel", true)
			
			if hasTimer or hasScore or hasTeam then
				gui:Destroy()
				print("[GUICleanup] Destroyed game GUI: " .. gui.Name)
			end
		end
	end
end

function GUICleanup.Init()
	-- Initial cleanup
	GUICleanup.DestroyExistingGuis()
	
	-- Cleanup every second for a while to catch late-loading GUIs
	task.spawn(function()
		for i = 1, 30 do
			task.wait(1)
			GUICleanup.DestroyExistingGuis()
		end
	end)
	
	-- Watch for new GUIs being added
	playerGui.ChildAdded:Connect(function(child)
		if child:IsA("ScreenGui") and not PROTECTED_GUI_NAMES[child.Name] then
			task.wait(0.1)
			-- Check if it's a game mode GUI
			local hasTimer = child:FindFirstChild("Timer", true) or child:FindFirstChild("TimerLabel", true)
			local hasScore = child:FindFirstChild("Score", true) or child:FindFirstChild("ScoreLabel", true)
			
			if hasTimer or hasScore then
				child:Destroy()
				print("[GUICleanup] Destroyed new game GUI: " .. child.Name)
			end
		end
	end)
	
	print("[GUICleanup] GUI cleanup active")
end

return GUICleanup
