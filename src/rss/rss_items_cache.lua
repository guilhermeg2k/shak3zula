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
  local MAX_ITEMS = 100;
  local current_cached_items = RssCache.get(rss_provider)

  -- Remove half of items on the current cache
  if #current_cached_items > MAX_ITEMS then
    for i = #current_cached_items, math.floor(MAX_ITEMS / 2), -1 do
      table.remove(current_cached_items, i)
    end
  end

  -- Add new cache into current cache
  table.move(current_cached_items, 1, #current_cached_items, #cache + 1, cache)

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
