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
					warn("An array in the table has a missing value in the array")
					return false
				end
			end
			lastIndex = i
		end
		if structure then
			for name, value2 in pairs(value) do
				if type(name) ~= "number" then
					return false
				end
				if structure[name] then
					if not structure[name]:validate(value2) then
						return false
					end
				else
					warn(string.format("Unknown key '%s' in structure with value '%s'", name, tostring(value2)))
				end
			end
		else
			for i, _ in pairs(value) do
				if type(i) ~= "number" then
					return false
				end
			end
			return true
		end
	else
		return false
	end
end

function class:serialize(value)
	return value
end

function class:deserialize(value)
	return value
end

return function(structure)
	return class.new(structure)
end