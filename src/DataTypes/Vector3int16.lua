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
	return typeof(value) == "Vector3"
end

function class:serialize(value)
	if value == nil then return nil end
	-- Serializes the Vector3 as an array of numbers (x, y, z)
	-- This would be serialized as a `string.pack()`'d string, but datastores don't support what it outputs unfortunately, maybe in the future when it does, we can use that instead.
	return {value.X,value.Y,value.Z}
end

function class:deserialize(value)
	if value == nil then return nil end
	-- Deserializes the Vector3 from an array of numbers (x, y, z)
	return Vector3int16.new(unpack(value))
end

return class.new()