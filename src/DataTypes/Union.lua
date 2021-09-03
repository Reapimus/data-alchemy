local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new(types)
	return setmetatable({
		__types = types;
	}, class)
end

function class:validate(value)
	for _, t in pairs(self.__types) do
		if t:validate(value) then
			return true
		end
	end
	return false
end

function class:serialize(value)
	if value == nil then return nil end
	for i, t in pairs(self.__types) do
		if t:validate(value) then
			return {i,t:serialize(value)}
		end
	end
end

function class:deserialize(value)
	if value == nil then return nil end
	return self.__types[value[1]]:deserialize(value)
end

return function(...)
	return class.new({...})
end