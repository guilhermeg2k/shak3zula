local DB = require('src.db')

local ExpenseCategory = {}

function ExpenseCategory.insert(name)
  local insert_stmt = DB.conn:prepare([[
        INSERT INTO expense_categories(name) VALUES (:name)
    ]])

  insert_stmt:bind_names({
    name = name,
  })

  insert_stmt:step()
  return insert_stmt:finalize()
end

function ExpenseCategory.list()
  local items = {}

  for row in DB.conn:nrows('select * from expense_categories') do
    table.insert(items, row)
  end

  return items
end

return ExpenseCategory
