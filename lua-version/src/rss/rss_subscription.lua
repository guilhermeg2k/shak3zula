local DB = require('src.db')
local pprint = require('lib.pprint')

local RssSubscription = {
  providers = {
    ['hltv'] = {
      name = 'HLTV',
      description = 'HLTV.org is the leading Counter-Strike site in the world, featuring news, demos, pictures, statistics, on-site coverage and much much more!',
      link = 'https://www.hltv.org/rss/news',
    },
    ['vlr'] = {
      name = 'VLR',
      description = 'A competitive valorant community -- news, events, matches, discussion, streams, stats, and more',
      link = 'https://www.vlr.gg/rss',
    },
  },
}

function RssSubscription.insert(rss_provider, telegram_chat_id, telegram_user_id)
  local insert_stmt = DB.conn:prepare([[
        INSERT INTO rss_subscriptions(rss_provider, telegram_chat_id, telegram_user_id) VALUES (:rss_provider, :telegram_chat_id, :telegram_user_id)
    ]])

  insert_stmt:bind_names({
    rss_provider = rss_provider,
    telegram_user_id = telegram_user_id,
    telegram_chat_id = telegram_chat_id,
  })

  insert_stmt:step()
  return insert_stmt:finalize()
end

function RssSubscription.listBy(rss_provider, telegram_user_id)
  local items = {}

  local select_stmt_str = 'SELECT * FROM rss_subscriptions WHERE rss_provider = :rss_provider'

  if telegram_user_id then
    select_stmt_str = select_stmt_str .. ' AND telegram_user_id = :telegram_user_id'
  end

  local select_stmt = DB.conn:prepare(select_stmt_str)

  select_stmt:bind_names({
    rss_provider = rss_provider,
    telegram_user_id = telegram_user_id,
  })

  for row in select_stmt:nrows() do
    table.insert(items, row)
  end

  return items
end

function RssSubscription.list()
  local items = {}

  for row in DB.conn:nrows('select * from rss_subscriptions') do
    table.insert(items, row)
  end

  return items
end

function RssSubscription.remove(rss_provider, telegram_user_id)
  local delete_stmt = DB.conn:prepare([[
        DELETE FROM rss_subscriptions WHERE rss_provider = :rss_provider AND telegram_user_id = :telegram_user_id 
      ]])

  delete_stmt:bind_names({
    rss_provider = rss_provider,
    telegram_user_id = telegram_user_id,
  })

  delete_stmt:step()
  return delete_stmt:finalize()
end

return RssSubscription
