local Util = {}

function Util.str_split(str, delimiters)
    local elements = {}
    local pattern = '([^' .. delimiters .. ']+)'
    string.gsub(str, pattern, function(value) elements[#elements + 1] = value; end);
    return elements
end

return Util
