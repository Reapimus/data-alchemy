--!strict
local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

class.ClassName = "Column"

function class.new(type_: {}, default: any?, nullable: boolean?, onUpdate: any?): {}
	-- Enforce parameter restrictions
	assert(type_ and type(type_) == "table", "Invalid argument #1 to Column.new (Expected a 'DataType' object)")
	if default ~= nil and type(default) ~= "function" then
		assert(type_:validate(default), "Invalid argument #2 to Column.new (Type mismatch)")
	end
	if onUpdate ~= nil then
		assert(type(onUpdate) == "function", "Invalid argument #3 to Column.new (Expected a 'function'")
	end
	return setmetatable({
		Type = type_;
		Default = default;
		Nullable = nullable == nil and true or nullable ~= nil and nullable;
		OnUpdate = onUpdate;
	}, class)
end

function class:validate(value: any): boolean
	-- Validate the value against the column's type, and its properties
	if not self.Nullable and value == nil then
		return false, "This column does not support nil values."
	end
	return value == nil and self.Nullable or self.Type:validate(value)
end

function class:serialize(value: any): any
	-- Serialize the value based on the type
	return self.Type:serialize(value)
end

function class:deserialize(value: any): any
	-- Deserialize the value based on the type
	return self.Type:deserialize(value)
end

return function(...)
	return class.new(...)
end