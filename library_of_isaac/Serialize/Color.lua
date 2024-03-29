local KEYS = {"R", "G", "B", "A", "RO", "GO", "BO"}
local OBJECT_NAME = "Color"


function TSIL.Serialize.DeserializeColor(color)
    if type(color) ~= "table" then
        error("Failed to deserialize a " .. OBJECT_NAME .. " object since the provided object was not a table")
    end

    local numbers = TSIL.Utils.Tables.GetNumbersFromTable(color, OBJECT_NAME, table.unpack(KEYS))

    if numbers[1] == nil then
        error("Failed to deserialize a " .. OBJECT_NAME .. " as the provided object did not have a value for: R")
    elseif numbers[2] == nil then
        error("Failed to deserialize a " .. OBJECT_NAME .. " as the provided object did not have a value for: G")
    elseif numbers[3] == nil then
        error("Failed to deserialize a " .. OBJECT_NAME .. " as the provided object did not have a value for: B")
    end

    return Color(numbers[1], numbers[2], numbers[3], numbers[4], numbers[5], numbers[6], numbers[7])
end


function TSIL.Serialize.IsSerializedColor(object)
    if type(object) ~= "table" then
        return false
    end

    return TSIL.Utils.Tables.TableHasKeys(object, table.unpack(KEYS)) and object[TSIL.Enums.SerializationBrand.COLOR] ~= nil
end


function TSIL.Serialize.SerializeColor(color)
    if not TSIL.IsaacAPIClass.IsColor(color) then
        error("Failed to serialize a " .. OBJECT_NAME .. " object since the provided object was not a userdata " .. OBJECT_NAME .. " class.")
    end

    local colorTable = {}
    TSIL.Utils.Tables.CopyUserdataValuesToTable(color, KEYS, colorTable)
    colorTable[TSIL.Enums.SerializationBrand.COLOR] = ""
    return colorTable
end