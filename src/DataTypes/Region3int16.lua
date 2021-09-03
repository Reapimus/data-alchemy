local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new()
	return setmetatable({}, class)
end

function class:validate(value)
	return typeof(value) == "Region3int16"
end

function class:serialize(value)
	if value == nil then return nil end
	local cf, size = value.CFrame, value.Size
	local regionStart = cf.Position - size/2
	local regionEnd = cf.Position + size/2
	return {regionStart.X,regionStart.Y,regionStart.Z,regionEnd.X,regionEnd.Y,regionEnd.Z}
end

function class:deserialize(value)
	if value == nil then return nil end
	local regionStart = Vector3.new(value[1],value[2],value[3])
	local regionEnd = Vector3.new(value[4],value[5],value[6])
	return Region3int16.new(regionStart, regionEnd)
end

return class.new()