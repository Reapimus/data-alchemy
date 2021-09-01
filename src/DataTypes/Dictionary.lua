local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new(structure)
	return setmetatable({
		__structure = structure;
	}, class)
end

function class:validate(value)
	local structure = self.__structure
	if type(value) == "table" then
		if structure then
			for name, value2 in pairs(value) do
				if type(name) == "number" then
					return false, "Mixed dictionaries aren't supported by datastores"
				end
				if structure[name] then
					if not structure[name]:validate(value2) then
						return false, "A value in the array has an invalid type"
					end
				else
					warn(string.format("Unknown key '%s' in structure with value '%s'", name, tostring(value2)))
				end
			end
		else
			for i, _ in pairs(value) do
				if type(i) == "number" then
					return false, "Mixed dictionaries aren't supported by datastores"
				end
			end
		end
		return true
	else
		return false
	end
end

function class:serialize(value)
	local result = {}
	if value then
		for i, v in pairs(value) do
			result[i] = self.__structure[i]:serialize(v)
		end
	end
	return result
end

function class:deserialize(value)
	return value
end

return function(structure)
	return class.new(structure)
end