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
	return typeof(value) == "DateTime"
end

function class:serialize(value: DateTime)
	if value == nil then return nil end
	return value:ToIsoDate()
end

function class:deserialize(value: string)
	if value == nil then return nil end
	return DateTime.fromIsoDate(value)
end

return class.new()