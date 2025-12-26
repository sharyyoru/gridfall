-- Gridfall Character Manager
-- Handles character appearance, disables accessories, applies soldier look

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")

local Shared = require(ReplicatedStorage:WaitForChild("Shared"))
local Constants = Shared.Constants

local CharacterManager = {}

-- Store original character descriptions for potential restoration
local originalDescriptions: {[Player]: HumanoidDescription} = {}

function CharacterManager.RemoveAccessoriesAndClothing(character: Model)
	-- Remove all accessories
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Accessory") then
			child:Destroy()
		end
	end
	
	-- Remove shirts and pants (we'll apply our own)
	local shirt = character:FindFirstChildOfClass("Shirt")
	if shirt then
		shirt:Destroy()
	end
	
	local pants = character:FindFirstChildOfClass("Pants")
	if pants then
		pants:Destroy()
	end
	
	local shirtGraphic = character:FindFirstChildOfClass("ShirtGraphic")
	if shirtGraphic then
		shirtGraphic:Destroy()
	end
end

function CharacterManager.ApplySoldierAppearance(character: Model, player: Player)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Wait a frame to ensure character is fully loaded
	task.wait()
	
	-- Remove accessories and existing clothing
	CharacterManager.RemoveAccessoriesAndClothing(character)
	
	-- Apply body colors
	local bodyColors = character:FindFirstChildOfClass("BodyColors")
	if not bodyColors then
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = character
	end
	
	local soldierColors = Constants.SOLDIER_APPEARANCE.BodyColors
	bodyColors.HeadColor = soldierColors.HeadColor
	bodyColors.TorsoColor = soldierColors.TorsoColor
	bodyColors.LeftArmColor = soldierColors.LeftArmColor
	bodyColors.RightArmColor = soldierColors.RightArmColor
	bodyColors.LeftLegColor = soldierColors.LeftLegColor
	bodyColors.RightLegColor = soldierColors.RightLegColor
	
	-- Apply default soldier clothing
	local shirt = Instance.new("Shirt")
	shirt.Name = "Shirt"
	shirt.ShirtTemplate = Constants.SOLDIER_APPEARANCE.DefaultShirtId
	shirt.Parent = character
	
	local pants = Instance.new("Pants")
	pants.Name = "Pants"
	pants.PantsTemplate = Constants.SOLDIER_APPEARANCE.DefaultPantsId
	pants.Parent = character
	
	-- Ensure player's actual skin is shown on arms and head
	-- We need to keep the player's actual body parts visible
	CharacterManager.SetupPlayerArms(character, player)
end

function CharacterManager.SetupPlayerArms(character: Model, player: Player)
	-- This ensures the player's actual avatar arms are visible
	-- The arms will show the player's skin tone from their avatar
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	-- Get player's HumanoidDescription to get their skin tone
	local success, description = pcall(function()
		return Players:GetHumanoidDescriptionFromUserId(player.UserId)
	end)
	
	if success and description then
		-- Store original description
		originalDescriptions[player] = description
		
		-- Apply only the body colors from player's avatar to arms and head
		local bodyColors = character:FindFirstChildOfClass("BodyColors")
		if bodyColors then
			-- Keep player's actual skin color for arms and head
			local headColor = description.HeadColor
			local leftArmColor = description.LeftArmColor
			local rightArmColor = description.RightArmColor
			
			if headColor ~= Color3.new(0, 0, 0) then
				bodyColors.HeadColor3 = headColor
			end
			if leftArmColor ~= Color3.new(0, 0, 0) then
				bodyColors.LeftArmColor3 = leftArmColor
			end
			if rightArmColor ~= Color3.new(0, 0, 0) then
				bodyColors.RightArmColor3 = rightArmColor
			end
		end
		
		-- Apply the player's face
		local head = character:FindFirstChild("Head")
		if head then
			local face = head:FindFirstChildOfClass("Decal")
			if face and description.Face ~= 0 then
				face.Texture = "rbxassetid://" .. tostring(description.Face)
			end
		end
	end
end

function CharacterManager.OnCharacterAdded(character: Model, player: Player)
	-- Wait for humanoid to be ready
	local humanoid = character:WaitForChild("Humanoid", 10)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not hrp then return end
	
	-- Apply soldier appearance
	CharacterManager.ApplySoldierAppearance(character, player)
	
	-- Set up character stats - PURE Roblox defaults
	humanoid.WalkSpeed = Constants.CHARACTER.DefaultWalkSpeed
	humanoid.JumpPower = Constants.CHARACTER.DefaultJumpPower
	humanoid.UseJumpPower = true
	humanoid.JumpHeight = 0
	
	-- Basic server-side setup - NO custom physics
	hrp.Anchored = false
	
	print("[CharacterManager] Applied soldier appearance and basic setup to " .. player.Name)
end

function CharacterManager.OnPlayerAdded(player: Player)
	player.CharacterAdded:Connect(function(character)
		CharacterManager.OnCharacterAdded(character, player)
	end)
	
	-- Handle if character already exists
	if player.Character then
		CharacterManager.OnCharacterAdded(player.Character, player)
	end
end

function CharacterManager.OnPlayerRemoving(player: Player)
	-- Clean up stored description
	originalDescriptions[player] = nil
end

function CharacterManager.Init()
	-- Connect player events
	Players.PlayerAdded:Connect(CharacterManager.OnPlayerAdded)
	Players.PlayerRemoving:Connect(CharacterManager.OnPlayerRemoving)
	
	-- Handle existing players
	for _, player in ipairs(Players:GetPlayers()) do
		CharacterManager.OnPlayerAdded(player)
	end
	
	print("[CharacterManager] Initialized")
end

return CharacterManager
