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
	return typeof(value) == "Faces"
end

function class:serialize(value)
	if value == nil then return nil end
	local axises = {value.Top,value.Bottom,value.Front,value.Back,value.Left,value.Right}
	local res = ""
	for i = 1, 6 do
		res ..= axises[i] and "1" or "0"
	end
	return res
end

function class:deserialize(value)
	if value == nil then return nil end
	local hasAxises = {}
	for i = 1, 6 do
		if string.sub(value, i, i) == "1" then
			table.insert(hasAxises, axisMap[i])
		end
	end
	return Faces.new(unpack(hasAxises))
end

return class.new()