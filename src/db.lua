local sqlite3 = require("lsqlite3")

local DB_PATH = "data/bot.db"
local DB = { conn = sqlite3.open(DB_PATH) }

function DB:create_tables()
	return self.conn:execute([[
        BEGIN TRANSACTION;

        CREATE TABLE IF NOT EXISTS expense_categories (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS expense_groups (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL
        );

        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY,
            value REAL NOT NULL,
            name TEXT,
            date TEXT NOT NULL,
            repeat_amount INTEGER,
            category_id INTEGER NOT NULL,
            group_id INTEGER,

            FOREIGN KEY (category_id)
            REFERENCES expense_categories (id),

            FOREIGN KEY (group_id)
            REFERENCES expense_group (id)
        );

        COMMIT;
    ]])
end

return DB
