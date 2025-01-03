local DB = require('src.db')
local Bot = require('src.bot')

local create_tables_status_code = DB:create_tables()
assert(create_tables_status_code == 0, 'Failed to create tables')

Bot.init()
