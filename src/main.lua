local DB = require('db')
local Bot = require('bot')

local create_tables_err_code = DB:create_tables()
assert(create_tables_err_code == 0, 'Failed to create tables')
Bot.init()
