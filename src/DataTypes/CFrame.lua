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
	return typeof(value) == "CFrame"
end

function class:serialize(value)
	if value == nil then return nil end
	return {value:GetComponents()}
end

function class:deserialize(value)
	if value == nil then return nil end
	return CFrame.new(unpack(value))
end

return class.new()