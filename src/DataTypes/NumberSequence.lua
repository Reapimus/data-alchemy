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
	for _, keypoint: NumberSequenceKeypoint in pairs(value.Keypoints) do
		table.insert(res, {keypoint.Time,keypoint.Value,keypoint.Envelope})
	end
	return res
end

function class:deserialize(value)
	if value == nil then return nil end
	local points = {}
	for _, keypoint in pairs(value) do
		table.insert(points, NumberSequenceKeypoint.new(unpack(keypoint)))
	end
	return NumberSequence.new(points)
end

return class.new()