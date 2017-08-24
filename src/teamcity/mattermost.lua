local cjson = require "cjson"
local tools = require "tools"
local template = require 'resty.template'

local teamcity_url = tools.get_env_variable_with_arg('TEAMCITY_MATTERMOST_URL', 'room', nil)
local teamcity_user = tools.get_env_variable_with_arg('TEAMCITY_MATTERMOST_USER', 'user', 'teamcity')
local teamcity_server_url = tools.get_env_variable_with_arg('TEAMCITY_SERVER_URL', 'teamcity_server', nil)
local teamcity_server_auth = tools.get_env_variable_with_arg('TEAMCITY_SERVER_AUTH', 'teamcity_auth', nil)

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local triggered_by = data.triggeredBy

-- parse triggered_by message which is of the following format:
-- Finish Build Trigger; <project-name> :: <build-configuration>, build #8
local trigger_type, project_config = string.match(triggered_by, "(.*); (.*)")
local project_name, build_configuration, build_number = string.match(project_config, "(.*) :: (.*), build #([0-9]+)")

-- Now fetch teamcity build information
local project_data, build_configuration_data, build_number_data = tools.fetch_teamcity_build_data(
    teamcity_server_url,
    teamcity_server_auth,
    project_name,
    build_configuration,
    build_number
)

local message_tmpl = template.new("[{* p.name *}]({* p.webUrl *}) :: [{* bc.name *}]({* bc.webUrl *}] :: [build #{* bn.number *}]({* bn.webUrl *}) :: **{* bn.status *}** :: `{* bn.statusText *}`")
message_tmpl.p = project_data
message_tmpl.bc = build_configuration_data
message_tmpl.bn = build_number_data
local message = tostring(message_tmpl)

ngx.say('message: ', message)

local res, err = tools.send_mattermost_message(
  teamcity_url,
  message,
  teamcity_user
)

ngx.say(cjson.encode({status='ok'}))
