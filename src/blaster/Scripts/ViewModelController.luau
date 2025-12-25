--!nocheck
-- ViewModelController - Modified to NOT interfere with movement
-- Copy this to ReplicatedStorage.Blaster.Scripts.ViewModelController

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Constants = require(ReplicatedStorage.Blaster.Constants)

local camera = Workspace.CurrentCamera
local viewModels = ReplicatedStorage.Blaster.ViewModels

local ViewModelController = {}
ViewModelController.__index = ViewModelController

function ViewModelController.new(blaster: Tool)
	local handle = blaster:WaitForChild("Handle")
	local sounds = blaster:WaitForChild("Sounds")

	local viewModelName = blaster:GetAttribute(Constants.VIEW_MODEL_ATTRIBUTE)
	local viewModelTemplate = viewModels[viewModelName]

	local viewModel = viewModelTemplate:Clone()
	local muzzle = viewModel:FindFirstChild("MuzzleAttachment", true)
	assert(muzzle, `{viewModel} is missing MuzzleAttachment!`)

	local animator = viewModel.AnimationController.Animator
	local animationsFolder = viewModel.Animations

	viewModel.Parent = ReplicatedStorage

	local animations = {}
	for _, animation in animationsFolder:GetChildren() do
		local animationTrack = animator:LoadAnimation(animation)
		animations[animation.Name] = animationTrack
	end
	
	-- Get player's arm color to apply to ViewModel
	local player = Players.LocalPlayer
	local armColor = Color3.fromRGB(204, 142, 105) -- Default skin tone
	if player.Character then
		local rightArm = player.Character:FindFirstChild("Right Arm") or player.Character:FindFirstChild("RightUpperArm")
		if rightArm then
			armColor = rightArm.Color
		end
	end
	
	-- Apply player's skin color to ViewModel arms
	for _, part in ipairs(viewModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local name = part.Name:lower()
			if name:find("arm") or name:find("hand") then
				part.Color = armColor
			end
		end
	end

	local self = {
		enabled = false,
		blaster = blaster,
		handle = handle,
		model = viewModel,
		muzzle = muzzle,
		animations = animations,
		toolInstances = {},
		connections = {},
		stride = 0,
		bobbing = 0,
	}
	setmetatable(self, ViewModelController)

	return self
end

function ViewModelController:update(deltaTime: number)
	-- Hide tool instances
	for _, instance in self.toolInstances do
		instance.LocalTransparencyModifier = 1
	end

	-- View model bobbing animation
	local moveSpeed = (self.handle.AssemblyLinearVelocity * Vector3.new(1, 0, 1)).Magnitude
	local bobbingSpeed = moveSpeed * Constants.VIEW_MODEL_BOBBING_SPEED
	local bobbing = math.min(bobbingSpeed, 1)

	self.stride = (self.stride + bobbingSpeed * deltaTime) % (math.pi * 2)
	self.bobbing = self.bobbing + (bobbing - self.bobbing) * math.min(deltaTime * Constants.VIEW_MODEL_BOBBING_TRANSITION_SPEED, 1)

	local x = math.sin(self.stride)
	local y = math.sin(self.stride * 2)
	local bobbingOffset = Vector3.new(x, y, 0) * Constants.VIEW_MODEL_BOBBING_AMOUNT * self.bobbing
	local bobbingCFrame = CFrame.new(bobbingOffset)

	self.model:PivotTo(camera.CFrame * Constants.VIEW_MODEL_OFFSET * bobbingCFrame)
end

function ViewModelController:checkForToolInstance(instance: Instance)
	if not (instance:IsA("BasePart") or instance:IsA("Decal")) then
		return
	end

	local tool = instance:FindFirstAncestorOfClass("Tool")
	if not tool then
		return
	end

	table.insert(self.toolInstances, instance)
end

function ViewModelController:hideToolInstances()
	local character = self.blaster.Parent

	table.insert(
		self.connections,
		character.DescendantAdded:Connect(function(descendant: Instance)
			self:checkForToolInstance(descendant)
		end)
	)

	table.insert(
		self.connections,
		character.DescendantRemoving:Connect(function(descendant: Instance)
			local index = table.find(self.toolInstances, descendant)
			if index then
				table.remove(self.toolInstances, index)
			end
		end)
	)

	for _, descendant in character:GetDescendants() do
		self:checkForToolInstance(descendant)
	end
end

function ViewModelController:stopHidingToolInstances()
	table.clear(self.toolInstances)
	for _, conn in self.connections do
		conn:Disconnect()
	end
	table.clear(self.connections)
end

function ViewModelController:getMuzzlePosition(): Vector3
	return self.muzzle.WorldPosition
end

function ViewModelController:playShootAnimation()
	self.animations.Shoot:Play(0)
	self.muzzle.FlashEmitter:Emit(1)
	self.muzzle.CircleEmitter:Emit(1)
end

function ViewModelController:playReloadAnimation(reloadTime: number)
	self.animations.Shoot:Stop()
	local speed = self.animations.Reload.Length / reloadTime
	self.animations.Reload:Play(Constants.VIEW_MODEL_RELOAD_FADE_TIME, 1, speed)
end

function ViewModelController:enable()
	if self.enabled then
		return
	end
	self.enabled = true

	RunService:BindToRenderStep(
		Constants.VIEW_MODEL_BIND_NAME,
		Enum.RenderPriority.Camera.Value + 2,
		function(deltaTime: number)
			self:update(deltaTime)
		end
	)
	self.model.Parent = Workspace
	self:hideToolInstances()

	self.animations.Idle:Play()
	self.animations.Equip:Play(0)
end

function ViewModelController:disable()
	if not self.enabled then
		return
	end
	self.enabled = false

	RunService:UnbindFromRenderStep(Constants.VIEW_MODEL_BIND_NAME)
	self.model.Parent = nil
	self:stopHidingToolInstances()

	for _, animation in self.animations do
		animation:Stop(0)
	end
end

function ViewModelController:destroy()
	self:stopHidingToolInstances()
	self:disable()
	self.model:Destroy()
end

return ViewModelController
