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
```

The Float DataType is a datatype specifying a number that may contain decimal places. It will only accept a number.

---

## Integer

```lua
DataAlchemy.Integer -> Integer
```

The Integer DataType is a datatype specifying a number that can only be a full number, it will only accept a number and will automatically round the number down to a full number.

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

---

## DateTime

```lua
DataAlchemy.DateTime -> DateTime
```

The DateTime DataType is a datatype specifying a Roblox `DateTime` datatype, it will automatically handle serialization of the datatype to the datastore and deserialization when getting the key in order to make using them as painless as possible for the developer.