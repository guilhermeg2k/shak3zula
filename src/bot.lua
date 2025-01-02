local BOT_TOKEN = os.getenv('BOT_TOKEN')
local CHAT_ID = os.getenv('CHAT_ID')
assert(CHAT_ID ~= nil, 'CHAT_ID must be defined')

local bot_api = require('lib.telegram-bot-lua.core').configure(BOT_TOKEN)
local util = require('src.util')
local pprint = require('lib.pprint')

local Expense = require('src.expense.expense')
local ExpenseCategory = require('src.expense.expense_category')
local ExpenseGroup = require('src.expense.expense_group')
local HLTV = require('src.hltv.hltv')

local Bot = {}

function Bot.init()
  Bot.defineHandlers()

  local bot_api_cr = coroutine.create(bot_api.run)
  local hltv_news_cr = coroutine.create(Bot.startHLTVCoroutine)

  while true do
    coroutine.resume(bot_api_cr)
    coroutine.resume(hltv_news_cr)
  end
end

function Bot.defineHandlers()
  function bot_api.on_message(message)
    local user_texts = util.str_split(message.text, ' ')
    local cmd = user_texts[1]

    if cmd == '/add' then
      return Bot.handlerAddExpense(message, user_texts)
    end

    if cmd == '/list' then
      return Bot.handlerListExpenses(message)
    end

    if cmd == '/add-expense-category' then
      return Bot.handlerAddExpenseCategory(message, user_texts)
    end

    if cmd == '/list-expense-categories' then
      return Bot.handlerListExpenseCategory(message)
    end

    if cmd == '/add-expense-group' then
      return Bot.handlerAddExpenseGroup(message, user_texts)
    end

    if cmd == '/list-expense-groups' then
      return Bot.handlerListExpenseGroup(message)
    end

    if cmd == '/hltv-news' then
      return Bot.handlerHLTVNews(message)
    end
  end
end

function Bot.startHLTVCoroutine()
  local check_news_timeout = 60
  local news_limit = 10
  local last_news = {}

  while true do
    local new_news = {}
    local news = HLTV.getNews()

    for _, n in ipairs(news) do
      local is_new_news = true

      for _, ln in ipairs(last_news) do
        if n.title == ln.title then
          is_new_news = false
          break
        end
      end

      if is_new_news then
        table.insert(new_news, n)
      end
    end

    last_news = news

    if #new_news > 0 then
      local news_msg = string.format('<b>HLTV update:</b>\n', news_limit)

      for i = 1, math.min(#new_news, news_limit) do
        local n = new_news[i]
        news_msg = news_msg .. string.format('<a href="%s">%s 🔗</a>\n', n.link, n.title)
      end

      local link_preview_options = { is_disabled = true }
      bot_api.send_message(CHAT_ID, news_msg, nil, 'HTML', nil, link_preview_options)
    end

    util.coroutineSleep(check_news_timeout)
  end
end

function Bot.sendCodeMsg(message_chat_id, title, text)
  local full_text = '```' .. title .. '\n' .. text .. '```'
  bot_api.send_message(message_chat_id, full_text, nil, 'MarkdownV2')
end

function Bot.sendSuccessMsg(message_chat_id, text)
  bot_api.send_message(message_chat_id, '✅ ' .. text)
end

function Bot.sendErrorMsg(message_chat_id, text)
  bot_api.send_message(message_chat_id, '❌ ' .. text)
end

function Bot.handlerHLTVNews(message)
  local news = HLTV.getNews()
  local news_limit = 10
  local news_msg = string.format('<b>Last %i HLTV News:</b>\n', news_limit)

  for i = 1, math.min(#news, news_limit) do
    local n = news[i]
    news_msg = news_msg .. string.format('<a href="%s">%s 🔗</a>\n', n.link, n.title)
  end

  local link_preview_options = { is_disabled = true }
  print(message.chat.id)
  bot_api.send_message(message.chat.id, news_msg, nil, 'HTML', nil, link_preview_options)
end

function Bot.handlerListExpenseCategory(message)
  local exps_categories = ExpenseCategory.list()
  local full_text = 'ID NAME\n'

  for _, exp in ipairs(exps_categories) do
    full_text = full_text .. string.format('%i %s\n', exp.id, exp.name)
  end

  Bot.sendCodeMsg(message.chat.id, 'Categories', full_text)
end

function Bot.handlerAddExpenseCategory(message, user_texts)
  local name = user_texts[2]

  if ExpenseCategory.insert(name) == 0 then
    Bot.sendSuccessMsg(message.chat.id, 'Expense category added')
  else
    Bot.sendErrorMsg(message.chat.id, 'Failed to add expense category')
  end
end

function Bot.handlerListExpenseGroup(message)
  local exps_groups = ExpenseGroup.list()
  local full_text = 'ID NAME\n'

  for _, exp in ipairs(exps_groups) do
    full_text = full_text .. string.format('%i %s\n', exp.id, exp.name)
  end

  Bot.sendCodeMsg(message.chat.id, 'Groups', full_text)
end

function Bot.handlerAddExpenseGroup(message, user_texts)
  local name = user_texts[2]

  if ExpenseGroup.insert(name) == 0 then
    Bot.sendSuccessMsg(message.chat.id, 'Expense group added')
  else
    Bot.sendErrorMsg(message.chat.id, 'Failed to add expense group')
  end
end

function Bot.handlerAddExpense(message, user_texts)
  local name, value = user_texts[2], user_texts[3]
  local current_time = os.date('!%Y-%m-%dT%H:%M:%SZ')

  if Expense.insert(name, value, 1, current_time, 0) == 0 then
    Bot.sendSuccessMsg(message.chat.id, 'Expense added')
  else
    Bot.sendErrorMsg(message.chat.id, 'Failed to add expense')
  end
end

function Bot.handlerListExpenses(message)
  local exps = Expense.list()
  local full_text = ''

  for _, exp in ipairs(exps) do
    full_text = full_text .. string.format('%s - R$ %.2f\n', exp.name, exp.value)
  end

  bot_api.send_message(message.chat.id, full_text)
end

return Bot
