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
	return typeof(value) == "Rect"
end

function class:serialize(value)
	if value == nil then return nil end
	return {value.Min.X,value.Min.Y,value.Max.X,value.Max.Y}
end

function class:deserialize(value)
	if value == nil then return nil end
	return Rect.new(unpack(value))
end

return class.new()