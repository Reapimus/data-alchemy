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
	return type(value) == "number"
end

function class:serialize(value)
	return tonumber(value)
end

function class:deserialize(value)
	return tonumber(value)
end

return class.new()