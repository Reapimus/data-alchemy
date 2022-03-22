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
	return typeof(value) == "UDim2"
end

function class:serialize(value)
	if value == nil then return nil end
	-- Serializes the UDim2 as an array of numbers (scaleX, offsetX, scaleY, offsetY)
	return {value.X,value.Width,value.Y,value.Height}
end

function class:deserialize(value)
	if value == nil then return nil end
	-- Deserializes the UDim2 from an array of numbers (scaleX, offsetX, scaleY, offsetY)
	return UDim2.new(unpack(value))
end

return class.new()