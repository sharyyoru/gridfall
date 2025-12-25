-- Gridfall Utilities
-- Common utility functions

local Utils = {}

function Utils.lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end

function Utils.lerpVector3(a: Vector3, b: Vector3, t: number): Vector3
	return a:Lerp(b, t)
end

function Utils.formatNumber(num: number): string
	if num >= 1000000 then
		return string.format("%.1fM", num / 1000000)
	elseif num >= 1000 then
		return string.format("%.1fK", num / 1000)
	end
	return tostring(math.floor(num))
end

function Utils.formatTime(seconds: number): string
	local mins = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%d:%02d", mins, secs)
end

function Utils.deepCopy<T>(original: T): T
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	for key, value in pairs(original :: any) do
		copy[key] = Utils.deepCopy(value)
	end
	return copy :: any
end

function Utils.calculatePower(inventory: any): number
	local totalPower = 0
	local count = 0
	
	if inventory.EquippedWeapons then
		for _, weapon in pairs(inventory.EquippedWeapons) do
			if weapon then
				totalPower = totalPower + weapon.Power
				count = count + 1
			end
		end
	end
	
	if inventory.EquippedArmor then
		for _, armor in pairs(inventory.EquippedArmor) do
			if armor then
				totalPower = totalPower + armor.Power
				count = count + 1
			end
		end
	end
	
	return count > 0 and math.floor(totalPower / count) or 0
end

function Utils.getChildrenOfClass(parent: Instance, className: string): {Instance}
	local children = {}
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA(className) then
			table.insert(children, child)
		end
	end
	return children
end

function Utils.waitForChildOfClass(parent: Instance, className: string, timeout: number?): Instance?
	local startTime = tick()
	local maxTime = timeout or 10
	
	while tick() - startTime < maxTime do
		for _, child in ipairs(parent:GetChildren()) do
			if child:IsA(className) then
				return child
			end
		end
		task.wait(0.1)
	end
	return nil
end

return Utils
