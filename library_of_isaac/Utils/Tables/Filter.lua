function TSIL.Utils.Tables.Filter(toFilter, predicate)
	local filtered = {}	

	for index, value in pairs(toFilter) do
		if predicate(index, value) then
			filtered[#filtered+1] = value
		end
	end

	return filtered
end