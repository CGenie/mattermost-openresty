local cjson = require "cjson"
local template = require 'resty.template'
local tools = require "tools"

local mattermost_url = tools.get_env_variable_with_arg('PIPELINES_MATTERMOST_URL', 'room', nil)
local mattermost_user = tools.get_env_variable_with_arg('PIPELINES_MATTERMOST_USER', 'user', 'bitbucket')

local headers = ngx.req.get_headers()
local event = headers["X-Event-Key"]
local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message = nil

if event == 'repo:commit_status_updated' then
    if data.commit_status.type ~= 'build' then
        ngx.log(ngx.ERR, 'This is not a build')
        ngx.exit(400)
    end

    local commit_status_tmpl = template.new([[
**[{* repo.full_name *}]({* repo.links.html.href *})** :: [Test **{* commit_status.state *}**]({* commit_status.url *}) for branch _{* commit_status.refname *}_ ]])
    commit_status_tmpl.actor_tmpl = actor_tmpl
    commit_status_tmpl.commit_status = data.commit_status
    commit_status_tmpl.repo = data.repository
    message = tostring(commit_status_tmpl)
end

if not message then
    message = 'This is not implemented yet (event ' .. event .. '): ' .. data_
end

local res, err = tools.send_mattermost_message(
  mattermost_url,
  message,
  username
)

ngx.say(cjson.encode({status='ok'}))
