local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__call = function(_, options)
	return class.new(options)
end
class.__metatable = "LOCKED"

function class.new(options)
	return setmetatable(options and {
		__negative = options.Negative or false;
		__positive = options.Positive or false;
		__max = options.Max;
		__min = options.Min;
	} or {}, class)
end

function class:validate(value)
	if type(value) == "number" then
		if self.__negative and value >= 0 then
			return false, "Number must be negative"
		end
		if self.__positive and value < 0 then
			return false, "Number must be positive"
		end
		if self.__max and value > self.__max then
			return false, "Number is above max range"
		end
		if self.__min and value < self.__min then
			return false, "Number is below min range"
		end
		return true
	else
		return false
	end
end

function class:serialize(value)
	if value == nil then return nil end
	return math.floor(tonumber(value))
end

function class:deserialize(value)
	if value == nil then return nil end
	return math.floor(tonumber(value))
end

return class.new()