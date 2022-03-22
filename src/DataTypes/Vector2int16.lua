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
	return typeof(value) == "Vector2"
end

function class:serialize(value)
	if value == nil then return nil end
	-- Serializes the Vector2 as an array of numbers (x, y)
	-- This would be serialized as a `string.pack()`'d string, but datastores don't support what it outputs unfortunately, maybe in the future when it does, we can use that instead.
	return {value.X,value.Y}
end

function class:deserialize(value)
	if value == nil then return nil end
	-- Deserializes the Vector2 from an array of numbers (x, y)
	return Vector2int16.new(unpack(value))
end

return class.new()