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
	-- A union type is one that can be any of the types in the union, so we need to check that the value is one of those types
	for _, t in pairs(self.__types) do
		if t:validate(value) then
			return true
		end
	end
	return false
end

function class:serialize(value)
	if value == nil then return nil end
	-- Since a union type can be any of the types in the union, we need to check which type it is and serialize it based on that
	for i, t in pairs(self.__types) do
		if t:validate(value) then
			-- Storing the type in the table saves some extra work when deserializing
			return {i,t:serialize(value)}
		end
	end
end

function class:deserialize(value)
	if value == nil then return nil end
	-- Get what type the value is based on the first value in the array, and then deserialize the value gotten from the second value in the array
	return self.__types[value[1]]:deserialize(value[2])
end

return function(...)
	return class.new({...})
end