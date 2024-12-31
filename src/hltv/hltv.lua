local http = require('socket.http')
local htmlparser = require('htmlparser')

local HLTV = {}

function HLTV.getNews()
  local page = http.request('https://www.hltv.org')
  local root = htmlparser.parse(page, 10000)
  local article_els = root:select('.article')
  local news = {}

  for _, article_el in ipairs(article_els) do
    local link = article_el.attributes['href']
    local news_text_el = article_el('.newstext')[1]
    -- local img = e('img')[1].attributes['src']

    if not news_text_el then
      news_text_el = article_el('.featured-newstext')[1]
    end

    if news_text_el then
      table.insert(news, { text = news_text_el:getcontent(), link = string.format('www.hltv.org%s', link) })
    end
  end

  return news
end

return HLTV

-- local news_text = ''
-- for _, n in ipairs(news) do
--   news_text = news_text .. string.format('<a href="www.hltv.org%s">%s</a>\n', n.link, n.text)
-- end
--
-- bot_api.send_message(message.chat.id, news_text, nil, 'HTML', nil, { is_disabled = true })
