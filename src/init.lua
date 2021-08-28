local module = {}

module.String = require(script.DataTypes.String)
module.Float = require(script.DataTypes.Float)
module.Integer = require(script.DataTypes.Integer)
module.Boolean = require(script.DataTypes.Boolean)
module.DateTime = require(script.DataTypes.DateTime)
module.Enum = require(script.DataTypes.Enum)
module.Dictionary = require(script.DataTypes.Dictionary)
module.Array = require(script.DataTypes.Array)

module.Column = require(script.Classes.Model)
module.Model = require(script.Classes.Model)

return module