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
	return typeof(value) == "Color3"
end

function class:serialize(value)
	if value == nil then return nil end
	local r,g,b = math.floor(value.R*255), math.floor(value.G*255), math.floor(value.B*255)
    return string.format("#%X%X%X", r, g, b)
end

function class:deserialize(value)
	if value == nil then return nil end
	value = value:gsub("#","")
	local r, g, b = tonumber("0x"..value:sub(1,2)), tonumber("0x"..value:sub(3,4)), tonumber("0x"..value:sub(5,6))
	return Color3.new(r,g,b)
end

return class.new()