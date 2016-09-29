-- curl -i -X POST -d 'payload={"text": "Hello, this is some text.\nThis is more text."}' http://yourmattermost.com/hooks/xxx-generatedkey-xxx

local tools = require "tools"
local cjson = require "cjson"

local mattermost_url = os.getenv("SENTRY_MATTERMOST_URL")
if not mattermost_url then
    ngx.say("SENTRY_MATTERMOST_URL env variable not defined")
    return
end
local username = os.getenv("SENTRY_MATTERMOST_USER")
if not username then
    username = 'sentry'
end

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message = '**' .. data.project_name .. '** :: ' .. data.level .. ' :: [' .. data.message .. '](' .. data.url .. ')'

ngx.say('message: ', message)

local res, err = tools.send_mattermost_message(
  mattermost_url,
  message,
  username
)

ngx.say(
    "url:\n", mattermost_url,
    --"\n\ndata:\n", data,
    "\n\nresponse:\n", res.body,
    "\n\nerror:\n", err
)
