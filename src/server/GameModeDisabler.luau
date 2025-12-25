-- Gridfall Game Mode Disabler
-- Disables any existing team/match/timer systems from Studio

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterGui = game:GetService("StarterGui")

local GameModeDisabler = {}

function GameModeDisabler.DisableTeams()
	-- Remove all teams
	for _, team in ipairs(Teams:GetChildren()) do
		team:Destroy()
	end
	
	-- Set all players to neutral
	for _, player in ipairs(Players:GetPlayers()) do
		player.Neutral = true
		player.Team = nil
	end
	
	-- Prevent new players from being assigned teams
	Players.PlayerAdded:Connect(function(player)
		player.Neutral = true
		player.Team = nil
	end)
	
	print("[GameModeDisabler] Teams disabled")
end

function GameModeDisabler.DisableExistingScripts()
	-- Look for common game mode script names and disable them
	local scriptNamesToDisable = {
		"GameManager",
		"MatchManager", 
		"RoundManager",
		"TeamManager",
		"TimerScript",
		"GameTimer",
		"MatchTimer",
		"RoundTimer",
		"GameMode",
		"MainGame",
		"GameLogic",
		"MatchLogic",
	}
	
	-- Search in ServerScriptService
	for _, scriptName in ipairs(scriptNamesToDisable) do
		local script = ServerScriptService:FindFirstChild(scriptName, true)
		if script and script:IsA("Script") then
			script.Disabled = true
			print("[GameModeDisabler] Disabled script: " .. script:GetFullName())
		end
	end
	
	-- Search in Workspace
	for _, scriptName in ipairs(scriptNamesToDisable) do
		local script = workspace:FindFirstChild(scriptName, true)
		if script and script:IsA("Script") then
			script.Disabled = true
			print("[GameModeDisabler] Disabled script: " .. script:GetFullName())
		end
	end
end

function GameModeDisabler.DisableTimerGuis()
	-- Disable any timer/match GUIs in StarterGui
	local guiNamesToDisable = {
		"TimerGui",
		"MatchGui",
		"GameGui",
		"RoundGui",
		"TeamGui",
		"ScoreGui",
	}
	
	for _, guiName in ipairs(guiNamesToDisable) do
		local gui = StarterGui:FindFirstChild(guiName, true)
		if gui then
			if gui:IsA("ScreenGui") then
				gui.Enabled = false
			end
			print("[GameModeDisabler] Disabled GUI: " .. gui:GetFullName())
		end
	end
end

function GameModeDisabler.UnanchorPlayers()
	-- Make sure player characters aren't anchored
	local function unanchorCharacter(character)
		if not character then return end
		
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = false
			end
		end
		
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 16
			humanoid.JumpPower = 50
			humanoid.PlatformStand = false
		end
		
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			hrp.Anchored = false
		end
	end
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			unanchorCharacter(player.Character)
		end
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			unanchorCharacter(character)
		end)
	end
	
	-- Handle new players
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			task.wait(0.5)
			unanchorCharacter(character)
		end)
	end)
	
	print("[GameModeDisabler] Player unanchoring enabled")
end

function GameModeDisabler.Init()
	print("[GameModeDisabler] Disabling existing game systems...")
	
	GameModeDisabler.DisableTeams()
	GameModeDisabler.DisableExistingScripts()
	GameModeDisabler.DisableTimerGuis()
	GameModeDisabler.UnanchorPlayers()
	
	print("[GameModeDisabler] All existing game systems disabled")
end

return GameModeDisabler
