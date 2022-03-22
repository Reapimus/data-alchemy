local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

local axisMap = {
	Enum.NormalId.Top;
	Enum.NormalId.Bottom;
	Enum.NormalId.Front;
	Enum.NormalId.Back;
	Enum.NormalId.Left;
	Enum.NormalId.Right;
}

function class.new()
	return setmetatable({}, class)
end

function class:validate(value)
	return typeof(value) == "Axes"
end

function class:serialize(value)
	if value == nil then return nil end
	-- Serializes the Axes object into a 6 character string of 0's and 1's
	local axises = {value.Top,value.Bottom,value.Front,value.Back,value.Left,value.Right}
	local res = ""
	for i = 1, 6 do
		res ..= axises[i] and "1" or "0"
	end
	return res
end

function class:deserialize(value)
	if value == nil then return nil end
	-- Deserializes the 6 character string of 0's and 1's into a Axes object
	local hasAxises = {}
	for i = 1, 6 do
		if string.sub(value, i, i) == "1" then
			table.insert(hasAxises, axisMap[i])
		end
	end
	return Axes.new(unpack(hasAxises))
end

return class.new()