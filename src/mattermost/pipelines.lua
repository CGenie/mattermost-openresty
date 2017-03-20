local tools = require "tools"
local cjson = require "cjson"

local mattermost_url = tools.get_env_variable_with_arg('PIPELINES_MATTERMOST_URL', 'room', nil)
local mattermost_user = tools.get_env_variable_with_arg('PIPELINES_MATTERMOST_USER', 'user', 'bitbucket')

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message = nil

local commit_status = data.commit_status

if commit_status.type ~= 'build' then
    ngx.log(ngx.ERR, 'This is not a build')
    ngx.exit(400)
end

local state = commit_status.state
local url = commit_status.url
local repository = data.repository
local branch = commit_status.refname

local repo_text = '**[' .. repository.full_name .. '](' .. repository.links.html.href .. ')**'
local test_text = '[Test ' .. state .. '](' .. url .. ')'
local branch_text = '_[' .. branch .. '](' .. commit_status.links.commits.href .. ')_'

message = repo_text .. ' :: ' .. test_text .. ' for branch ' .. branch_text

local res, err = tools.send_mattermost_message(
  mattermost_url,
  message,
  username
)

ngx.log(ngx.ERR, data_)
