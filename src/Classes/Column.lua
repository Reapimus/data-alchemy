local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new(type_, default, onUpdate)
	assert(type_, "Invalid argument #1 to Column.new (Expected a 'DataType' object)")
	if default ~= nil then
		assert(type_:validate(default), "Invalid argument #2 to Column.new (Type mismatch)")
	end
	if onUpdate ~= nil then
		assert(type(onUpdate) == "function", "Invalid argument #3 to Column.new (Expected a 'function'")
	end
	return setmetatable({
		ClassName = "Column";
		Type = type_;
		Default = default;
		OnUpdate = onUpdate;
	}, class)
end

function class:validate(value)
	return self.Type:validate(value)
end

function class:serialize(value)
	return self.Type:serialize(value)
end

function class:deserialize(value)
	return self.Type:deserialize(value)
end

return function(...)
	return class.new(...)
end