!!! caution
	This guide is still a work in progress, nothing here is guaranteed to be complete or fully explained yet.

In Data-Alchemy, a `Model` is a class that allows you to define `Column` instances that define how the data in a Roblox Datastore should be treated and handled.

A model can be defined as such:

```lua
local DataAlchemy = require(game.ReplicatedStorage.DataAlchemy)

local OurModel = DataAlchemy.Model.new("DataStoreName")
```

Adding onto this, we can next define the columns of our model by setting indexes in our Model class to newly created Column objects like so:

```lua
local DataAlchemy = require(game.ReplicatedStorage.DataAlchemy)
local Column = DataAlchemy.Column
local String = DataAlchemy.String
local Number = DataAlchemy.Number

local OurModel = DataAlchemy.Model.new("DataStoreName")

OurModel.Name = Column.new(String(30), "")
OurModel.Bio = Column.new(String(300), "")
OurModel.Avatar = Column.new(Number, 0)
```

In this example, we have created a model where `Name` is a string that can have a max of 30 characters and a default of a blank string, `Bio` is a string with a max of 300 characters and a default of a blank string, and `Avatar` is a number that defaults to zero.

!!! info
	For more information on DataTypes, checkout the [DataTypes](guide/datatypes) guide!

