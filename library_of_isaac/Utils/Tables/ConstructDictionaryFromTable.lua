function TSIL.Utils.Tables.ConstructDictionaryFromTable(oldTable)
    local dictionary = {}

    for _, v in pairs(oldTable) do
        dictionary[v] = true
    end

    return dictionary
end
