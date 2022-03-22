local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new(structure, strict)
	if structure then
		for name, value in pairs(structure) do
			if type(value) == "table" and value.ClassName == "Column" then
				continue
			else
				error("Invalid argument #1 to Dictionary.new (Expected a dictionary 'Column' objects)")
			end
		end
	end
	return setmetatable({
		__structure = structure;
		__strict = strict or false;
	}, class)
end

function class:validate(value)
	local structure = self.__structure
	if type(value) == "table" then
		if structure then
			-- If the value is a table, and we have a structure, then we need to check that the structure is valid
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
					if self.__strict then
						return false, string.format("Unknown key '%s' in structure with value '%s'", name, tostring(value2))
					end
				end
			end
		else
			for i, _ in pairs(value) do
				if type(i) == "number" then
					-- Make sure user error cannot occur by enforcing datastore rules
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
			-- Only serialize the values that are in the structure, if the structure even exists
			if self.__structure and self.__structure[i] then
				result[i] = self.__structure[i]:serialize(v)
			else
				result[i] = v
			end
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