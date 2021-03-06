local module = {}

-- The main library module is just a ton of requires for main classes, and all the datatype modules for the Column class to use
module.String = require(script.DataTypes.String)
module.Float = require(script.DataTypes.Float)
module.Integer = require(script.DataTypes.Integer)
module.Boolean = require(script.DataTypes.Boolean)
module.DateTime = require(script.DataTypes.DateTime)
module.Enum = require(script.DataTypes.Enum)
module.Dictionary = require(script.DataTypes.Dictionary)
module.Array = require(script.DataTypes.Array)
module.Color3 = require(script.DataTypes.Color3)
module.ColorSequence = require(script.DataTypes.ColorSequence)
module.NumberRange = require(script.DataTypes.NumberRange)
module.NumberSequence = require(script.DataTypes.NumberSequence)
module.BrickColor = require(script.DataTypes.BrickColor)
module.Axes = require(script.DataTypes.Axes)
module.Faces = require(script.DataTypes.Faces)
module.CFrame = require(script.DataTypes.CFrame)
module.Vector3 = require(script.DataTypes.Vector3)
module.Vector3int16 = require(script.DataTypes.Vector3int16)
module.Vector2 = require(script.DataTypes.Vector2)
module.Vector2int16 = require(script.DataTypes.Vector2int16)
module.Region3 = require(script.DataTypes.Region3)
module.Region3int16 = require(script.DataTypes.Region3int16)
module.Rect = require(script.DataTypes.Rect)
module.UDim = require(script.DataTypes.UDim)
module.UDim2 = require(script.DataTypes.UDim2)

module.Column = require(script.Classes.Column)
module.Model = require(script.Classes.Model)

return module