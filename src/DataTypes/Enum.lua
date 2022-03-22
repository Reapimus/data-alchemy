local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new(enum: Enum | Enums)
	-- Can either select from a specified Enum or select an Enum from the entire Enums object
	return setmetatable({
		ENUM = enum
	}, class)
end

function class:validate(value)
	return typeof(value) == "EnumItem" and value.EnumType == self.ENUM or self.ENUM == Enum
end

function class:serialize(value: Enum | EnumItem)
	if value == nil then return nil end
	if self.ENUM == Enum then
		return tostring(value)
	else
		-- Used to serialize value.Value instead, replaced with the name due to the risk of it becoming invalid if Roblox changes the value of the enum
		return value.Name
	end
end

function class:deserialize(value)
	if value then
		if self.ENUM == Enum then
			return Enum[value]
		else
			return self.ENUM[value]
		end
	else
		return nil
	end
end

return function(enum: Enum)
	return class.new(enum)
end