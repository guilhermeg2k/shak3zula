local BOT_TOKEN = os.getenv("BOT_TOKEN")
local bot_api = require("telegram-bot-lua.core").configure(BOT_TOKEN)
local util = require("src.util")
local pprint = require("lib.pprint")
local Expense = require("src.expense.expense")
local ExpenseCategory = require("src.expense.expense_category")
local ExpenseGroup = require("src.expense.expense_group")

local Bot = {}

function Bot.init()
	function bot_api.on_message(message)
		local user_texts = util.str_split(message.text, " ")
		local cmd = user_texts[1]

		pprint(user_texts)

		if cmd == "/add" then
			return Bot.handlerAddExpense(message, user_texts)
		end

		if cmd == "/list" then
			return Bot.handlerListExpenses(message)
		end

		if cmd == "/add-expense-category" then
			return Bot.handlerAddExpenseCategory(message, user_texts)
		end

		if cmd == "/list-expense-categories" then
			return Bot.handlerListExpenseCategory(message)
		end

		if cmd == "/add-expense-group" then
			return Bot.handlerAddExpenseGroup(message, user_texts)
		end

		if cmd == "/list-expense-groups" then
			return Bot.handlerListExpenseGroup(message)
		end
	end

	bot_api.run()
end

function Bot.sendCodeMsg(message_chat_id, title, text)
	local full_text = "```" .. title .. "\n" .. text .. "```"
	bot_api.send_message(message_chat_id, full_text, nil, "MarkdownV2")
end

function Bot.sendSuccessMsg(message_chat_id, text)
	bot_api.send_message(message_chat_id, "✅ " .. text)
end

function Bot.sendErrorMsg(message_chat_id, text)
	bot_api.send_message(message_chat_id, "❌ " .. text)
end

function Bot.handlerListExpenseCategory(message)
	local exps_categories = ExpenseCategory.list()
	local full_text = "ID NAME\n"

	for _, exp in ipairs(exps_categories) do
		full_text = full_text .. string.format("%i %s\n", exp.id, exp.name)
	end

	Bot.sendCodeMsg(message.chat.id, "Categories", full_text)
end

function Bot.handlerAddExpenseCategory(message, user_texts)
	local name = user_texts[2]

	if ExpenseCategory.insert(name) == 0 then
		Bot.sendSuccessMsg(message.chat.id, "Expense category added")
	else
		Bot.sendErrorMsg(message.chat.id, "Failed to add expense category")
	end
end

function Bot.handlerListExpenseGroup(message)
	local exps_groups = ExpenseGroup.list()
	local full_text = "ID NAME\n"

	for _, exp in ipairs(exps_groups) do
		full_text = full_text .. string.format("%i %s\n", exp.id, exp.name)
	end

	Bot.sendCodeMsg(message.chat.id, "Groups", full_text)
end

function Bot.handlerAddExpenseGroup(message, user_texts)
	local name = user_texts[2]

	if ExpenseGroup.insert(name) == 0 then
		Bot.sendSuccessMsg(message.chat.id, "Expense group added")
	else
		Bot.sendErrorMsg(message.chat.id, "Failed to add expense group")
	end
end

function Bot.handlerAddExpense(message, user_texts)
	local name, value = user_texts[2], user_texts[3]
	local current_time = os.date("!%Y-%m-%dT%H:%M:%SZ")

	if Expense.insert(name, value, 1, current_time, 0) == 0 then
		Bot.sendSuccessMsg(message.chat.id, "Expense added")
	else
		Bot.sendErrorMsg(message.chat.id, "Failed to add expense")
	end
end

function Bot.handlerListExpenses(message)
	local exps = Expense.list()
	local full_text = ""

	for _, exp in ipairs(exps) do
		full_text = full_text .. string.format("%s - R$ %.2f\n", exp.name, exp.value)
	end

	bot_api.send_message(message.chat.id, full_text)
end

return Bot
