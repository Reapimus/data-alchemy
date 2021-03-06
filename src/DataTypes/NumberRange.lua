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
	return typeof(value) == "NumberRange"
end

function class:serialize(value)
	if value == nil then return nil end
	-- Serializes the NumberRange as an array of numbers (min, max)
	return {value.Min,value.Max}
end

function class:deserialize(value)
	if value == nil then return nil end
	-- Deserializes the NumberRange from an array of numbers (min, max)
	return NumberRange.new(unpack(value))
end

return class.new()