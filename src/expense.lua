local DB = require('src.db')
local Expense = {}

function Expense.insert(name, value, category_id, date, repeat_amount)
    local insert_stmt = DB.conn:prepare([[
        INSERT INTO expenses(name, value, date, category_id, repeat_amount) VALUES (:name, :value, :date, :category_id, :repeat_amount)
    ]])

    insert_stmt:bind_names({
        name = name,
        value = value,
        date = date,
        repeat_amount = repeat_amount,
        category_id = category_id
    })

    insert_stmt:step()
    return insert_stmt:finalize()
end

function Expense.list()
    local items = {}

    for row in DB.conn:nrows('SELECT * FROM expenses') do
        table.insert(items, row)
    end

    return items
end

return Expense
