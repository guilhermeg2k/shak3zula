local json = require('json')
local pprint = require('lib.pprint')

local DB = require('src.db')

local RssCache = {}

function RssCache.insert(rss_provider, cache)
  local insert_stmt = DB.conn:prepare([[
        INSERT INTO rss_items_cache(rss_provider, cache) VALUES (:rss_provider, :cache)
    ]])

  insert_stmt:bind_names({
    rss_provider = rss_provider,
    cache = json.encode(cache),
  })

  insert_stmt:step()
  return insert_stmt:finalize()
end

function RssCache.update(rss_provider, cache)
  local insert_stmt = DB.conn:prepare([[
        UPDATE rss_items_cache set cache = :cache WHERE rss_provider = :rss_provider;
    ]])

  insert_stmt:bind_names({
    rss_provider = rss_provider,
    cache = json.encode(cache),
  })

  insert_stmt:step()
  return insert_stmt:finalize()
end

function RssCache.get(rss_provider)
  local select_stmt_str = 'SELECT * FROM rss_items_cache WHERE rss_provider = :rss_provider'

  local select_stmt = DB.conn:prepare(select_stmt_str)

  select_stmt:bind_names({
    rss_provider = rss_provider,
  })

  for row in select_stmt:nrows() do
    return json.decode(row.cache)
  end
end

return RssCache
