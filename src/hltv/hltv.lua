local http = require('socket.http')
local htmlparser = require('htmlparser')

local HLTV = {}

function HLTV.getNews()
  local page = http.request('https://www.hltv.org/rss/news')
  local root = htmlparser.parse(page)
  local articles = root:select('item')
  local news = {}

  for _, article in ipairs(articles) do
    local link = article('link')[1]:getcontent()
    local title = article('title')[1]:getcontent()

    if link then
      table.insert(news, { title = title, link = link })
    end
  end

  return news
end

return HLTV
