local class = {}
class.__index = class
class.__newindex = function()
	error("This class is read-only!", 2)
end
class.__metatable = "LOCKED"

function class.new()
	return setmetatable({}, class)
end

function class:validate(value)
	return typeof(value) == "NumberSequence"
end

function class:serialize(value)
	if value == nil then return nil end
	local res = {}
	for _, keypoint: ColorSequenceKeypoint in pairs(value.Keypoints) do
		local color = keypoint.Value
		local r,g,b = math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255)
    	local hex = string.format("#%X%X%X", r, g, b)
		table.insert(res, {keypoint.Time,hex})
	end
	return res
end

function class:deserialize(value)
	if value == nil then return nil end
	local points = {}
	for _, keypoint in pairs(value) do
		local hex = keypoint[2]
		hex = hex:gsub("#","")
		local r, g, b = tonumber("0x"..hex:sub(1,2)), tonumber("0x"..hex:sub(3,4)), tonumber("0x"..hex:sub(5,6))
		table.insert(points, ColorSequenceKeypoint.new(keypoint[1], Color3.new(r,g,b)))
	end
	return ColorSequence.new(points)
end

return class.new()