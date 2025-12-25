-- Gridfall Game Mode Disabler
-- AGGRESSIVELY disables ALL existing game systems from Studio

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")

local GameModeDisabler = {}

-- Names of OUR scripts/folders to NOT disable
local PROTECTED_NAMES = {
	["Server"] = true,
	["Shared"] = true,
	["Remotes"] = true,
	["Assets"] = true,
	["GridfallUI"] = true,
}

function GameModeDisabler.DisableTeams()
	-- Destroy all teams
	for _, team in ipairs(Teams:GetChildren()) do
		team:Destroy()
	end
	print("[GameModeDisabler] Teams destroyed")
end

function GameModeDisabler.DisableAllExistingScripts()
	-- Disable ALL scripts in ServerScriptService except our own
	for _, child in ipairs(ServerScriptService:GetChildren()) do
		if not PROTECTED_NAMES[child.Name] then
			if child:IsA("Script") then
				child.Disabled = true
				print("[GameModeDisabler] Disabled: " .. child.Name)
			elseif child:IsA("Folder") or child:IsA("ModuleScript") then
				-- Disable all scripts inside
				for _, desc in ipairs(child:GetDescendants()) do
					if desc:IsA("Script") then
						desc.Disabled = true
						print("[GameModeDisabler] Disabled: " .. desc:GetFullName())
					end
				end
			end
		end
	end
	
	-- Disable scripts in Workspace
	for _, desc in ipairs(workspace:GetDescendants()) do
		if desc:IsA("Script") and not PROTECTED_NAMES[desc.Name] then
			desc.Disabled = true
			print("[GameModeDisabler] Disabled workspace script: " .. desc.Name)
		end
	end
end

function GameModeDisabler.DestroyAllExistingGuis()
	-- Destroy ALL GUIs in StarterGui except ours
	for _, gui in ipairs(StarterGui:GetChildren()) do
		if not PROTECTED_NAMES[gui.Name] and gui:IsA("ScreenGui") then
			gui:Destroy()
			print("[GameModeDisabler] Destroyed GUI: " .. gui.Name)
		end
	end
	
	-- Also destroy GUIs in all player's PlayerGui
	for _, player in ipairs(Players:GetPlayers()) do
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, gui in ipairs(playerGui:GetChildren()) do
				if not PROTECTED_NAMES[gui.Name] and gui:IsA("ScreenGui") then
					-- Don't destroy our UI or Roblox core UI
					if gui.Name ~= "GridfallUI" and gui.Name ~= "HUDScreen" and gui.Name ~= "InventoryScreen" and gui.Name ~= "LoadingScreen" then
						gui:Destroy()
						print("[GameModeDisabler] Destroyed player GUI: " .. gui.Name)
					end
				end
			end
		end
	end
end

function GameModeDisabler.FixCharacterState(character)
	if not character then return end
	
	-- Unanchor all parts
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- Fix all states that could block movement
		humanoid.PlatformStand = false
		humanoid.Sit = false
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
		humanoid.AutoRotate = true
		
		-- Change state to running/idle
		humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
		task.wait(0.1)
		humanoid:ChangeState(Enum.HumanoidStateType.Running)
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.Anchored = false
	end
end

function GameModeDisabler.SetupCharacterFixer()
	local function setupPlayer(player)
		player.Neutral = true
		player.Team = nil
		
		local function onCharacterAdded(character)
			-- Wait for character to fully load
			local humanoid = character:WaitForChild("Humanoid", 10)
			if not humanoid then return end
			
			-- Initial fix
			task.wait(0.3)
			GameModeDisabler.FixCharacterState(character)
			
			-- Continuous fix for a few seconds to override any other scripts
			for i = 1, 20 do
				task.wait(0.25)
				GameModeDisabler.FixCharacterState(character)
			end
			
			-- Also fix when state changes
			humanoid.StateChanged:Connect(function(old, new)
				if new == Enum.HumanoidStateType.PlatformStanding or
				   new == Enum.HumanoidStateType.Seated then
					task.wait(0.1)
					GameModeDisabler.FixCharacterState(character)
				end
			end)
		end
		
		player.CharacterAdded:Connect(onCharacterAdded)
		if player.Character then
			onCharacterAdded(player.Character)
		end
	end
	
	-- Handle all players
	for _, player in ipairs(Players:GetPlayers()) do
		setupPlayer(player)
	end
	Players.PlayerAdded:Connect(setupPlayer)
	
	print("[GameModeDisabler] Character fixer enabled")
end

function GameModeDisabler.Init()
	print("[GameModeDisabler] AGGRESSIVELY disabling existing game systems...")
	
	GameModeDisabler.DisableTeams()
	GameModeDisabler.DisableAllExistingScripts()
	GameModeDisabler.DestroyAllExistingGuis()
	GameModeDisabler.SetupCharacterFixer()
	
	-- Continuously destroy unwanted GUIs for players joining
	Players.PlayerAdded:Connect(function(player)
		player.Neutral = true
		task.wait(1)
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, gui in ipairs(playerGui:GetChildren()) do
				if gui:IsA("ScreenGui") and gui.Name ~= "GridfallUI" and gui.Name ~= "HUDScreen" and gui.Name ~= "InventoryScreen" and gui.Name ~= "LoadingScreen" then
					gui:Destroy()
				end
			end
		end
	end)
	
	print("[GameModeDisabler] All existing game systems disabled")
end

return GameModeDisabler
