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

function SpawnManager.OnPlayerAdded(player: Player)
	-- Let Roblox handle spawning naturally - no custom teleporting
	-- Only clear invisible barriers if needed
	player.CharacterAdded:Connect(function(character)
		task.wait(1) -- Wait for character to fully load
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			SpawnManager.ClearInvisibleBarriers(humanoidRootPart.Position, character)
		end
	end)
end

function SpawnManager.ClearInvisibleBarriers(position: Vector3, character: Model?)
	local workspace = game:GetService("Workspace")
	local region = Region3.new(position - Vector3.new(10, 10, 10), position + Vector3.new(10, 10, 10))
	
	-- Find any parts in the spawn region that might be blocking movement
	for _, part in ipairs(workspace:FindPartsInRegion3(region, nil, math.huge)) do
		-- Skip important parts
		if part.Name == "Baseplate" or (character and part:IsDescendantOf(character)) or part:IsA("SpawnLocation") then
			continue
		end
		
		-- Check for invisible parts that could block movement
		if part.Transparency >= 0.5 and part.CanCollide and part.Size.X < 20 and part.Size.Y < 20 and part.Size.Z < 20 then
			-- Disable collision for suspicious invisible parts
			part.CanCollide = false
			print("[SpawnManager] Disabled collision for invisible barrier:", part.Name, part:GetFullName())
		end
	end
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
