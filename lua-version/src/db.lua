local sqlite3 = require('lsqlite3')

local DB_PATH = 'data/bot.db'
local DB = { conn = sqlite3.open(DB_PATH) }

function DB:create_tables()
  return self.conn:execute([[
        BEGIN TRANSACTION;

        CREATE TABLE IF NOT EXISTS rss_subscriptions (
            id INTEGER PRIMARY KEY,
            rss_provider TEXT NOT NULL,
            telegram_user_id INTEGER NOT NULL,
            telegram_chat_id INTEGER NOT NULL
        );

        CREATE TABLE IF NOT EXISTS rss_items_cache (
            id INTEGER PRIMARY KEY,
            rss_provider TEXT NOT NULL,
            cache TEXT NOT NULL
        );

        COMMIT;
    ]])
end

return DB
