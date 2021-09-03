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
	return {value.X,value.Y}
end

function class:deserialize(value)
	if value == nil then return nil end
	return Vector2int16.new(unpack(value))
end

return class.new()