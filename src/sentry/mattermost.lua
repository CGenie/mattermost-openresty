-- curl -i -X POST -d 'payload={"text": "Hello, this is some text.\nThis is more text."}' http://yourmattermost.com/hooks/xxx-generatedkey-xxx

local cjson = require "cjson"
local template = require "resty.template"
local tools = require "tools"

local mattermost_url = tools.get_env_variable_with_arg('SENTRY_MATTERMOST_URL', 'room', nil)
local mattermost_user = tools.get_env_variable_with_arg('SENTRY_MATTERMOST_USER', 'user', 'sentry')

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message_tmpl = template.new("**{* d.project_name *}** :: {* d.level *} :: [{* d.message *}]({* d.url *})")
message_tmpl.d = data
local message = tostring(message_tmpl)

ngx.say('message: ', message)

local res, err = tools.send_mattermost_message(
  mattermost_url,
  message,
  mattermost_user
)

ngx.say(cjson.encode({status='ok'}))
