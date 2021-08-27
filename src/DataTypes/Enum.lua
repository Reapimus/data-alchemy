local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new(enum: Enum)
	return setmetatable({
		ENUM = enum
	}, class)
end

function class:validate(value)
	return typeof(value) == "EnumItem" and value.EnumType == self.ENUM
end

function class:serialize(value)
	return value.Value
end

function class:deserialize(value)
	return self.ENUM[value]
end

return function(enum: Enum)
	return class.new(enum)
end