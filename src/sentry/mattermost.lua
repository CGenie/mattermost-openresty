-- curl -i -X POST -d 'payload={"text": "Hello, this is some text.\nThis is more text."}' http://yourmattermost.com/hooks/xxx-generatedkey-xxx

local tools = require "tools"
local cjson = require "cjson"

local sentry_url = tools.get_env_variable_with_arg('SENTRY_MATTERMOST_URL', 'room', nil)
local sentry_user = tools.get_env_variable_with_arg('SENTRY_MATTERMOST_USER', 'user', 'sentry')

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message = '**' .. data.project_name .. '** :: ' .. data.level .. ' :: [' .. data.message .. '](' .. data.url .. ')'

ngx.say('message: ', message)

local res, err = tools.send_mattermost_message(
  mattermost_url,
  message,
  sentry_user
)

ngx.say(
    "url:\n", mattermost_url,
    --"\n\ndata:\n", data,
    "\n\nresponse:\n", res.body,
    "\n\nerror:\n", err
)
