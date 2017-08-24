-- curl -i -X POST -d 'payload={"text": "Hello, this is some text.\nThis is more text."}' http://yourmattermost.com/hooks/xxx-generatedkey-xxx

local cjson = require "cjson"
local template = require "resty.template"
local tools = require "tools"

local mattermost_url = tools.get_env_variable_with_arg('BITBUCKET_MATTERMOST_URL', 'room', nil)
local mattermost_user = tools.get_env_variable_with_arg('BITBUCKET_MATTERMOST_USER', 'user', 'bitbucket')

local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message = nil
local actor_tmpl = template.new("{% if actor.links.avatar.href then %}![embedded image]({* actor.links.avatar.href *}) {% end %}")
local actor_display_tmpl = template.new("[{* actor.display_name *}]({* actor.links.html.href *})")
local push_tmpl = template.new([[
{* actor_tmpl *} **[{* repo.full_name *}]({* repo.links.html.href *})**/*[{* new_commit.name *}]({* new_commit.links.html.href *})* :: New commit from {* actor_display_tmpl *}:
```
{* new_commit.target.message *}
```
]])
push_tmpl.actor_tmpl = actor_tmpl
push_tmpl.actor_display_tmpl = actor_display_tmpl
local pullrequest_tmpl = template.new([[
{* actor_tmpl *} **[{* repo.full_name *}]({* repo.links.html.href *})** :: New pull request from {* actor_display_tmpl *}: *[{* pullrequest.title *}]({* pullrequest.links.html.href *})* ]])
pullrequest_tmpl.actor_tmpl = actor_tmpl
pullrequest_tmpl.actor_display_tmpl = actor_display_tmpl

local push = data.push
if push then
    actor_tmpl.actor = data.actor
    actor_display_tmpl.actor = data.actor
    push_tmpl.repo = data.repository
    push_tmpl.new_commit = push.changes[1].new
    message = tostring(push_tmpl)
end

local pullrequest = data.pullrequest
if pullrequest then
    actor_tmpl.actor = data.actor
    actor_display_tmpl.actor = data.actor
    pullrequest_tmpl.pullrequest = pullrequest
    pullrequest_tmpl.repo = pullrequest.destination.repository
    message = tostring(pullrequest_tmpl)
end

local comment = data.comment
if comment then
    local content = comment.content.raw
    local comment_href = comment.links.html.href
    local repository = data.repository
    local repo = repository.full_name
    local repo_href = repository.links.html.href
    local user = comment.user.display_name
    local user_href = comment.user.links.html.href

    -- now question is whether the comment is for pull request or for commit
    local commit = comment.commit
    if commit then
        local commit_hash = comment.commit.hash
        local commit_href = comment.commit.links.html.href
        local user = comment.user.display_name
        local user_href = comment.user.links.html.href
        message = '**[' .. repo .. '](' .. repo_href .. ')**/*[' .. commit_hash .. '](' .. commit_href .. ')* :: [New comment](' .. comment_href .. ') from [' .. user .. '](' .. user_href .. '):\n' .. content
    end

    local pull_request = comment.pullrequest
    if pull_request then
        local title = pull_request.title
        local pull_request_href = pullrequest.links.html.href
        message = '**[' .. repo .. '](' .. repo_href .. ')**/*[PR ' .. title .. '](' .. pull_request_href .. ')* :: [New comment](' .. comment_href .. ') from [' .. user .. '](' .. user_href .. '):\n' .. content
    end
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

ngx.say(cjson.encode({status='ok'}))
