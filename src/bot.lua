local BOT_TOKEN = os.getenv('BOT_TOKEN')

local bot_api = require('lib.telegram-bot-lua.core').configure(BOT_TOKEN)
local util = require('src.util')
local pprint = require('lib.pprint')

local RssSubscription = require('src.rss.rss_subscription')
local Rss = require('src.rss.rss')

local Bot = {
  cached_rss_items = {},
  invalid_rss_provider_msg = 'Invalid rss provider name. To list available providers use the command /list.rss',
}

function Bot.init()
  Bot.defineHandlers()

  local bot_api_cr = coroutine.create(bot_api.run)
  local rss_update_check_cr = coroutine.create(Bot.startRSSCoroutine)

  while true do
    coroutine.resume(bot_api_cr)
    coroutine.resume(rss_update_check_cr)
  end
end

function Bot.defineHandlers()
  function bot_api.on_message(message)
    if #message.text > 100 then
      return
    end

    local cmd = util.str_split(message.text, ' ')[1]
    pprint(message, cmd)

    if cmd == '/rss_list' then
      return Bot.handleListRss(message)
    end

    if cmd == '/rss_subscribe' then
      return Bot.handlerSubscribe(message)
    end

    if cmd == '/rss_unsubscribe' then
      return Bot.handlerUnsubscription(message)
    end
  end
end

function Bot.handleListRss(msg)
  local list_msg = '<b>List of available RSS providers: </b>\n\n'

  for provider_name, provider in pairs(RssSubscription.providers) do
    list_msg = list_msg .. string.format('<b>%s</b>: %s\n\n', provider_name, provider.description)
  end

  local link_preview_options = { is_disabled = true }
  bot_api.send_message(msg.chat.id, list_msg, nil, 'HTML', nil, link_preview_options)
end

function Bot.handlerSubscribe(msg)
  local args = util.str_split(msg.text, ' ')
  local provider = RssSubscription.providers[args[2]]

  if not provider then
    return Bot.sendErrorMsg(msg.chat.id, Bot.invalid_rss_provider_msg)
  end

  if #RssSubscription.listBy(provider.name, msg.from.id) > 0 then
    return Bot.sendErrorMsg(msg.chat.id, 'You are already subscribed to ' .. provider.name)
  end

  local insert_status_code = RssSubscription.insert(provider.name, msg.chat.id, msg.from.id)

  if insert_status_code ~= 0 then
    Bot.sendErrorMsg(msg.chat.id, 'Failed to subscribe to ' .. provider.name)
    return
  end

  Bot.sendSuccessMsg(msg.chat.id, 'You are now subscribed to ' .. args[2])
  Bot.sendRSSItems(msg.chat.id, provider)
end

function Bot.handlerUnsubscription(msg)
  local args = util.str_split(msg.text, ' ')
  local provider = RssSubscription.providers[args[2]]

  if not provider then
    return Bot.sendErrorMsg(msg.chat.id, Bot.invalid_rss_provider_msg)
  end

  if #RssSubscription.listBy(provider.name, msg.from.id) == 0 then
    return Bot.sendErrorMsg(msg.chat.id, 'You are not subscribed to ' .. provider.name)
  end

  local delete_status_code = RssSubscription.remove(provider.name, msg.from.id)

  if delete_status_code ~= 0 then
    Bot.sendErrorMsg(msg.chat.id, 'Failed to unsubscribe from ' .. provider.name)
    return
  end

  Bot.sendSuccessMsg(msg.chat.id, 'You are now unsubscribed from ' .. args[2])
end

function Bot.sendRSSItems(chat_id, provider)
  local items = Rss.getItems(provider.link)
  local items_limit = 10
  local news_msg = string.format('<b>🆕 %s Last updates:</b>\n', provider.name)

  for i = 1, math.min(#items, items_limit) do
    local n = items[i]
    news_msg = news_msg .. string.format('<a href="%s">%s 🔗</a>\n', n.link, n.title)
  end

  local link_preview_options = { is_disabled = true }
  bot_api.send_message(chat_id, news_msg, nil, 'HTML', nil, link_preview_options)
end

function Bot.getRssNewItems(provider)
  local new_items = {}
  local items = Rss.getItems(provider.link)

  for _, item in ipairs(items) do
    local is_new_item = true

    if Bot.cached_rss_items[provider.name] == nil then
      Bot.cached_rss_items[provider.name] = {}
    end

    for _, cachedItem in ipairs(Bot.cached_rss_items[provider.name]) do
      if item.title == cachedItem.title then
        is_new_item = false
        break
      end
    end

    if is_new_item then
      table.insert(new_items, item)
    end
  end

  if #items > 0 then
    Bot.cached_rss_items[provider.name] = items
  end

  return new_items
end

function Bot.sendRssUpdate(provider)
  local rss_subscribers = RssSubscription.listBy(provider.name)
  if #rss_subscribers == 0 then
    return
  end

  local msg_limit_per_sec = 30
  local items_limit = 10
  local last_items = Bot.getRssNewItems(provider)

  if #last_items > 0 then
    local chat_ids = {}
    for _, subs in ipairs(rss_subscribers) do
      table.insert(chat_ids, subs.telegram_chat_id)
    end

    local update_msg = string.format('<b>🆕 %s update:</b>\n', provider.name)

    for i = 1, math.min(#last_items, items_limit) do
      local item = last_items[i]
      update_msg = update_msg .. string.format('<a href="%s">%s 🔗</a>\n', item.link, item.title)
    end

    local link_preview_options = { is_disabled = true }

    for index, chat_id in ipairs(chat_ids) do
      bot_api.send_message(chat_id, update_msg, nil, 'HTML', nil, link_preview_options)
      -- This insures bot doesn't overflows telegram api msg limit per second https://core.telegram.org/bots/faq#my-bot-is-hitting-limits-how-do-i-avoid-this
      if index % msg_limit_per_sec == 0 then
        util.coroutineSleep(1)
      end
    end
  end
end

function Bot.startRSSCoroutine()
  local check_news_timeout = 60 -- seconds

  while true do
    for _, provider in pairs(RssSubscription.providers) do
      Bot.sendRssUpdate(provider)
    end

    util.coroutineSleep(check_news_timeout)
  end
end

function Bot.sendSuccessMsg(message_chat_id, text)
  bot_api.send_message(message_chat_id, '✅ ' .. text)
end

function Bot.sendErrorMsg(message_chat_id, text)
  bot_api.send_message(message_chat_id, '❌ ' .. text)
end

function Bot.sendCodeMsg(message_chat_id, title, text)
  local full_text = '```' .. title .. '\n' .. text .. '```'
  bot_api.send_message(message_chat_id, full_text, nil, 'MarkdownV2')
end

return Bot
