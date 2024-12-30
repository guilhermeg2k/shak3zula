local DB = require("src.db")

local ExpenseGroup = {}

function ExpenseGroup.insert(name)
	local insert_stmt = DB.conn:prepare([[
        INSERT INTO expense_groups(name) VALUES (:name)
    ]])

	insert_stmt:bind_names({
		name = name,
	})

	insert_stmt:step()
	return insert_stmt:finalize()
end

function ExpenseGroup.list()
	local items = {}

	for row in DB.conn:nrows("select * from expense_groups") do
		table.insert(items, row)
	end

	return items
end

return ExpenseGroup
