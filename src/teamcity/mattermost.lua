-- Sample payload:
-- {
--     "name": "Echo :: Build",
--     "url": "http://127.0.0.1:8080/viewType.html?buildTypeId=Echo_Build",
--     "build": {
--         "full_url": "http://127.0.0.1:8080/viewLog.html?buildTypeId=Echo_Build&buildId=14",
--         "build_id": "7",
--         "status": "success",
--         "scm": {
--             "url": "https://github.com/evgeny-goldin/echo-service.git",
--             "branch": "origin/master",
--             "commit": "6bef6af1f43fb3e5e6d73f1e3332e82dae1f55d4"
--                },
--         "artifacts": {
--             "echo-service-0.0.1-SNAPSHOT.jar": {
--                 "s3": "https://s3-eu-west-1.amazonaws.com/evgenyg-bakery/Echo::Build/7/echo-service-0.0.1-SNAPSHOT.jar",
--                 "archive": "http://127.0.0.1:8080/repository/download/Echo_Build/7/echo-service-0.0.1-SNAPSHOT.jar"
--             }
--         }
--     }
-- }

local tools = require "tools"
local cjson = require "cjson"

local teamcity_url = tools.get_env_variable_with_arg('TEAMCITY_MATTERMOST_URL', 'room', nil)
local teamcity_user = tools.get_env_variable_with_arg('TEAMCITY_MATTERMOST_USER', 'user', 'teamcity')

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
--local message = '**' .. data.project_name .. '** :: ' .. data.level .. ' :: [' .. data.message .. '](' .. data.url .. ')'
--local message = '**' .. data.name .. '** :: [' .. data.build.status .. '](' .. data.build.full_url .. ')'
local triggered_by = data.triggeredBy
local message = '**' .. triggeredBy .. '**'

ngx.say('message: ', message)

local res, err = tools.send_mattermost_message(
  mattermost_url,
  message,
  mattermost_user
)

ngx.say(cjson.encode({status='ok'}))
