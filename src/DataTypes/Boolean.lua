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
	return type(value) == "boolean"
end

function class:serialize(value)
	-- Serialize the boolean as 1 or 0 to save space
	return value and 1 or 0
end

function class:deserialize(value)
	-- Deserialize the boolean from 1 or 0
	return value == 1
end

return class.new()