local Util = {}

function Util.str_split(str, delimiters)
  local elements = {}
  local pattern = '([^' .. delimiters .. ']+)'
  string.gsub(str, pattern, function(value)
    elements[#elements + 1] = value
  end)
  return elements
end

function Util.coroutineSleep(seconds)
  local start = os.time()

  repeat
    coroutine.yield()
  until os.difftime(os.time(), start) >= seconds
end

return Util
