local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new(maxLength)
	return setmetatable({
		MAXLENGTH = maxLength or math.huge;
	}, class)
end

function class:validate(value)
	if type(value) == "string" then
		return #value <= self.MAXLENGTH
	end
end

function class:serialize(value)
	return tostring(value)
end

function class:deserialize(value)
	return value
end

return function(maxLength: number)
	return class.new(maxLength)
end