local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new(enum: Enum)
	return setmetatable({
		ENUM = enum
	}, class)
end

function class:validate(value)
	return typeof(value) == "EnumItem" and value.EnumType == self.ENUM or self.ENUM == Enum
end

function class:serialize(value)
	if value == nil then return nil end
	if self.ENUM == Enum then
		return tostring(value)
	else
		return value.Value
	end
end

function class:deserialize(value)
	if value then
		if self.ENUM == Enum then
			return Enum[value]
		else
			for _, v in pairs(self.ENUM:GetEnumItems()) do
				if v.Value == value then
					return v
				end
			end
		end
	else
		return nil
	end
end

return function(enum: Enum)
	return class.new(enum)
end