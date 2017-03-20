-- curl -i -X POST -d 'payload={"text": "Hello, this is some text.\nThis is more text."}' http://yourmattermost.com/hooks/xxx-generatedkey-xxx

local tools = require "tools"
local cjson = require "cjson"

local mattermost_room = ngx.args.room
local url_env = "BITBUCKET_MATTERMOST_URL"
if mattermost_room then
    url_env = url_env .. "_" .. mattermost_room:upper()
end
local username_env = "BITBUCKET_MATTERMOST_USER"
local mattermost_user = ngx.args.user
if mattermost_user then
    username_env = username_env .. "_" .. mattermost_user:upper()
end

local mattermost_url = os.getenv(url_env)
if not mattermost_url then
    ngx.say(url_env .. " env variable not defined")
    return
end
local username = os.getenv(username_env)
if not username then
    username = 'bitbucket'
end

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message = nil

local push = data.push
if push then
    local actor = data.actor.display_name
    local actor_href = data.actor.links.html.href
    local avatar_href = data.actor.links.avatar.href
    local avatar_message = ''
    if avatar_href then
        avatar_message = '![embedded image](' .. avatar_href .. ') '
    end
    local repository = data.repository
    local repo = repository.full_name
    local repo_href = repository.links.html.href
    local new_commit = push.changes[1].new
    local target = new_commit.target
    local branch_name = new_commit.name
    local branch_href = new_commit.links.html.href
    local href = target.links.html.href
    local commit_message, num_rep = string.gsub(target.message, "\n", "")
    message = avatar_message .. '**[' .. repo .. '](' .. href .. ')**/*[' .. branch_name .. '](' .. branch_href .. ')* :: New commit from [' .. actor .. '](' .. actor_href .. '): ' .. '\n```\n' .. commit_message .. '\n```'
end

local pullrequest = data.pullrequest
if pullrequest then
    local actor = data.actor.display_name
    local repo = pullrequest.destination.repository.full_name
    local repo_href = pullrequest.destination.repository.links.html.href
    local href = pullrequest.links.html.href
    local title = pullrequest.title
    message = '**[' .. repo .. '](' .. href .. ')** :: New pull request from ' .. actor .. ': ' .. href .. ' (*' .. title .. '*)'
end

if not message then
    message = 'This is not implemented yet: ' .. data_
end

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
