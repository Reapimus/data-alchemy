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
		local lastIndex
		for i, _ in pairs(value) do
			if lastIndex then
				if math.abs(lastIndex-i) > 1 then
					warn("There is a missing value in the array")
					return false, "There is a missing value in the array"
				end
			end
			lastIndex = i
		end
		if structure then
			for name, v in pairs(value) do
				if type(name) ~= "number" then
					return false, "Mixed dictionaries aren't supported by datastores"
				end
				if not structure:validate(v) then
					return false, "A value in the array has an invalid type"
				end
			end
		else
			for i, _ in pairs(value) do
				if type(i) ~= "number" then
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
			result[i] = self.__structure:serialize(v)
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