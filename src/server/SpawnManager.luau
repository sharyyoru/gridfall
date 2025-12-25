-- Gridfall Spawn Manager
-- Handles player spawning at MainSpawn on Overheat map

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local SpawnManager = {}

local mainSpawn: SpawnLocation? = nil
local overheatMap: Model? = nil

function SpawnManager.FindMainSpawn()
	-- Look for MainSpawn in Workspace
	local workspace = game:GetService("Workspace")
	
	-- Find the Overheat map
	overheatMap = workspace:FindFirstChild(Constants.SPAWN.DefaultMapName)
	if not overheatMap then
		warn("[SpawnManager] Overheat map not found in Workspace")
	end
	
	-- Find MainSpawn
	mainSpawn = workspace:FindFirstChild(Constants.SPAWN.MainSpawnName) :: SpawnLocation?
	if not mainSpawn then
		-- Try to find it as a descendant
		mainSpawn = workspace:FindFirstChild(Constants.SPAWN.MainSpawnName, true) :: SpawnLocation?
	end
	
	if mainSpawn then
		-- Configure spawn
		if mainSpawn:IsA("SpawnLocation") then
			mainSpawn.Neutral = true
			mainSpawn.AllowTeamChangeOnTouch = false
			mainSpawn.Duration = 0
		end
		print("[SpawnManager] MainSpawn found and configured")
	else
		warn("[SpawnManager] MainSpawn not found - using default spawn")
	end
	
	-- Disable other spawn locations
	SpawnManager.DisableOtherSpawns()
end

function SpawnManager.DisableOtherSpawns()
	local workspace = game:GetService("Workspace")
	
	-- Find SpawnLocations folder and disable spawns inside
	local spawnLocations = workspace:FindFirstChild("SpawnLocations")
	if spawnLocations then
		for _, spawn in ipairs(spawnLocations:GetDescendants()) do
			if spawn:IsA("SpawnLocation") and spawn ~= mainSpawn then
				spawn.Enabled = false
			end
		end
		print("[SpawnManager] Disabled spawns in SpawnLocations folder")
	end
	
	-- Disable any other spawn locations that aren't MainSpawn
	for _, spawn in ipairs(workspace:GetDescendants()) do
		if spawn:IsA("SpawnLocation") and spawn ~= mainSpawn then
			if spawn.Name ~= Constants.SPAWN.MainSpawnName then
				spawn.Enabled = false
			end
		end
	end
end

function SpawnManager.GetSpawnCFrame(): CFrame
	if mainSpawn then
		return mainSpawn.CFrame + Vector3.new(0, 3, 0)
	end
	
	-- Fallback spawn position
	return CFrame.new(0, 10, 0)
end

function SpawnManager.OnPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		-- Teleport to main spawn after a brief delay
		task.wait(0.1)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
		if humanoidRootPart then
			humanoidRootPart.CFrame = SpawnManager.GetSpawnCFrame()
		end
	end)
end

function SpawnManager.Init()
	-- Find spawn points
	SpawnManager.FindMainSpawn()
	
	-- Set respawn time
	Players.RespawnTime = Constants.SPAWN.RespawnTime
	
	-- Connect player events
	Players.PlayerAdded:Connect(SpawnManager.OnPlayerAdded)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		SpawnManager.OnPlayerAdded(player)
	end
	
	print("[SpawnManager] Initialized")
end

return SpawnManager
