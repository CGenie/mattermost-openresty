local tools = require "tools"
local cjson = require "cjson"

local mattermost_url = tools.get_env_variable_with_arg('PIPELINES_MATTERMOST_URL', 'room', nil)
local mattermost_user = tools.get_env_variable_with_arg('PIPELINES_MATTERMOST_USER', 'user', 'bitbucket')

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message = nil

local res, err = tools.send_mattermost_message(
  mattermost_url,
  data_,
  username
)

ngx.log(ngx.ERR, data_)
