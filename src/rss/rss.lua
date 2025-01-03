local http = require('socket.http')
local htmlparser = require('htmlparser')

local Rss = {}

function Rss.getItems(rss_link)
  local page = http.request(rss_link)
  local root = htmlparser.parse(page)
  local articles = root:select('item')
  local items = {}

  for _, article in ipairs(articles) do
    local link = article('link')[1]:getcontent()
    local title = article('title')[1]:getcontent()

    if link then
      table.insert(items, { title = title, link = link })
    end
  end

  return items
end

return Rss
