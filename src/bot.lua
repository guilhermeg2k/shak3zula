local bot_key = os.getenv('BOT_API')
local bot_api = require('telegram-bot-lua.core').configure(bot_key)
local util = require('util')
local pprint = require('pprint')
local Expense = require('expense')

local Bot = {}

function Bot.init()
    function bot_api.on_message(message)
        local user_texts = util.str_split(message.text, ' ')
        local cmd = user_texts[1]

        pprint(user_texts)

        if cmd == '/add' then
            local name, value = user_texts[2], user_texts[3]
            local current_time = os.date("!%Y-%m-%dT%H:%M:%SZ")

            if Expense.insert(name, value, 1, current_time, 0) == 0 then
                bot_api.send_message(
                    message.chat.id,
                    '✅ Expense added with success'
                )
            else
                bot_api.send_message(
                    message.chat.id,
                    '❌ Failed to add expense'
                )
            end
        end

        if cmd == '/list' then
            local exps = Expense.list()
            local full_text = ''

            for _, exp in ipairs(exps) do
                full_text = full_text .. string.format('%s - R$ %.2f\n', exp.name, exp.value)
            end


            bot_api.send_message(
                message.chat.id,
                full_text
            )
        end
    end

    bot_api.run()
end

return Bot
