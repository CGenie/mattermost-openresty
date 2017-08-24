local tools = require "tools"
local cjson = require "cjson"

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

local project_message = '**[' .. project_data.name .. '](' .. project_data.webUrl .. ')**'
local build_configuration_message = '[' .. build_configuration_data.name .. '](' .. build_configuration_data.webUrl .. ')'
local build_number_message = '[build #' .. build_number_data.number .. '](' .. build_number_data.webUrl .. ') :: **' .. build_number_data.status .. '** :: `' .. build_number_data.statusText .. '`'
local message = project_message .. ' :: ' .. build_configuration_message .. ' :: ' .. build_number_message

ngx.say('message: ', message)

local res, err = tools.send_mattermost_message(
  teamcity_url,
  message,
  teamcity_user
)

ngx.say(cjson.encode({status='ok'}))
