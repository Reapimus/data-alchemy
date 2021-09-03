In Data Alchemy, DataTypes are a set of custom classes that are used by the library to validate, serialize, and deserialize keys in a table. They tell the library how this key should be confirmed to be valid, how this key should be converted in order to be saved to the datastore successfully, and how this key should be converted back from the datastore in order for you to interact with it painlessly.

In Data Alchemy, there currently exist 9 DataTypes, which will be listed below.

---

## String

```lua
DataAlchemy.String(MaxLength) -> String
```

The String DataType is a datatype specifying a string and uses a constructor that allows you to specify the maximum length of the string, if no max length is defined it defaults to infinity.

---

## Float

```lua
DataAlchemy.Float -> Float
DataAlchemy.Float(options) -> Float
```

The Float DataType is a datatype specifying a number that may contain decimal places. It will only accept a number.

When this is called like a constructor function, it should be provided a table of options as its first argument, these options can be:

```lua
{
    Negative = boolean;
    Positive = boolean;
    Min = number;
    Max = number;
}
```

Negative & Positive will enforce a rule where the number provided must be negative or positive depending on which you set to true, you shouldn't enable both at once.

Min and Max will enforce a rule where the number provided must be within the specified range (they can be specified on their own, without the presence of the other).

---

## Integer

```lua
DataAlchemy.Integer -> Integer
DatAlchemy.Integer(options) -> Integer
```

The Integer DataType is a datatype specifying a number that can only be a full number, it will only accept a number and will automatically round the number down to a full number.

Integer has an identical constructor function to Float

---

## Boolean

```lua
DataAlchemy.Boolean -> Boolean
```

The Boolean DataType is a datatype specifying a true or false value, it will only accept a boolean.

---

## Dictionary

```lua
DataAlchemy.Dictionary(structure) -> Dictionary
```

The Dictionary DataType is a datatype specifying a table that may only accept the keys and their specified DataTypes inside the `structure` argument provided when firing the constructor for the dictionary datatype. Its key names must be strings.

The format of the `structure` argument is:

```lua
{
    KEYNAME = DATATYPE;
}
```

---

## Array

```lua
DataAlchemy.Array(datatype) -> Array
```

The Array DataType is a datatype specifying a table that may only accept numbers as keys. The datatype will reject a value if it has a gap between two keys. `datatype` specifies what DataType should be used to validate all the keys in the array.

---

## Enum

```lua
DataAlchemy.Enum(enum) -> Enum
```

The Enum DataType is a datatype specifying a Roblox enum to use for the key, the `enum` argument will only accept an Enum and is used to construct a Enum datatype that will validate and properly serialize/deserialize a value used for this key.

Providing just the `Enum` container itself will make the Enum datatype only accept an Enum specifier (Meaning you should provide this key a value like `Enum.Material` instead of `Enum.Material.Air` for example).

---

## DateTime

```lua
DataAlchemy.DateTime -> DateTime
```

The DateTime DataType is a datatype specifying a Roblox `DateTime` datatype, it will automatically handle serialization of the datatype to the datastore and deserialization when getting the key in order to make using them as painless as possible for the developer.

---

## Roblox DataTypes

The following Roblox DataTypes have custom DataTypes specified in Data-Alchemy:

* Axes
* BrickColor
* CFrame
* Color3
* ColorSequence
* Faces
* NumberRange
* NumberSequence
* Rect
* Region3
* Region3int16
* UDim
* UDim2
* Vector2
* Vector2int16
* Vector3
* Vector3int16

---

## Union

```lua
DataAlchemy.Union(datatype, ...) -> Union
```

The Union DataType is a datatype specifying a column that accepts any of the datatypes specified within the constructor. Example construction of a Union datatype could look like:

```lua
DataAlchemy.Union(DataAlchemy.String, DataAlchemy.Number, DataAlchemy.Boolean)
```