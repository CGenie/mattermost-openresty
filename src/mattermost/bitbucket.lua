-- curl -i -X POST -d 'payload={"text": "Hello, this is some text.\nThis is more text."}' http://yourmattermost.com/hooks/xxx-generatedkey-xxx

local cjson = require "cjson"
local template = require "resty.template"
local tools = require "tools"

local mattermost_url = tools.get_env_variable_with_arg('BITBUCKET_MATTERMOST_URL', 'room', nil)
local mattermost_user = tools.get_env_variable_with_arg('BITBUCKET_MATTERMOST_USER', 'user', 'bitbucket')

local headers = ngx.req.get_headers()
local event = headers["X-Event-Key"]
local data_ = tools.get_ngx_data()
local data = cjson.decode(data_)
local message = nil
local actor_tmpl = template.new("{% if actor.links.avatar.href then %}![embedded image]({* actor.links.avatar.href *}) {% end %}")
local actor_display_tmpl = template.new("[{* actor.display_name *}]({* actor.links.html.href *})")

if data.actor then
    actor_tmpl.actor = data.actor
end

if event == 'repo:push' then
    local push_tmpl = template.new([[
{* actor_tmpl *} **[{* repo.full_name *}]({* repo.links.html.href *})**/*[{* new_commit.name *}]({* new_commit.links.html.href *})* :: New commit from {* actor_display_tmpl *}:
```
{* new_commit.target.message *}
``` ]])
    actor_display_tmpl.actor = data.actor
    push_tmpl.actor_tmpl = actor_tmpl
    push_tmpl.actor_display_tmpl = actor_display_tmpl
    push_tmpl.repo = data.repository
    push_tmpl.new_commit = data.push.changes[1].new
    message = tostring(push_tmpl)
end

if event == 'pullrequest:created' then
    local pullrequest_tmpl = template.new([[
{* actor_tmpl *} **[{* repo.full_name *}]({* repo.links.html.href *})** :: New pull request from {* actor_display_tmpl *}: *[{* pullrequest.title *}]({* pullrequest.links.html.href *})* ]])
    actor_display_tmpl.actor = data.actor
    pullrequest_tmpl.actor_tmpl = actor_tmpl
    pullrequest_tmpl.actor_display_tmpl = actor_display_tmpl
    pullrequest_tmpl.pullrequest = data.pullrequest
    pullrequest_tmpl.repo = data.pullrequest.destination.repository
    message = tostring(pullrequest_tmpl)
end

if event == 'repo:commit_comment_created' then
    local commit_comment_tmpl = template.new([[
{* actor_tmpl *} **[{* repo.full_name *}]({* repo.links.html.href *})**/*[{* comment.commit.hash *}]({* comment.commit.links.html.href *})* :: [New comment]({* comment.links.html.href *}) from {* user_display_tmpl *}:
```
{* comment.content.raw *}
``` ]])
actor_display_tmpl.actor = data.comment.user
    commit_comment_tmpl.actor_tmpl = actor_tmpl
    commit_comment_tmpl.user_display_tmpl = actor_display_tmpl
    commit_comment_tmpl.comment = data.comment
    commit_comment_tmpl.repo = data.repository
    message = tostring(commit_comment_tmpl)
end

if event == 'pullrequest:comment_created' then
    local pullrequest_comment_tmpl = template.new([[
'{* actor_tmpl *} **[{* repo.full_name *}]({* repo.links.html.href *})**/*[PR {* comment.pullrequest.title *}]({* comment.pullrequest.links.html.href *})* :: [New comment]({* comment.links.html.href *}) from {* user_display_tmpl *}:
```
{* comment.content.raw *}
``` ]])
    actor_display_tmpl.actor = data.comment.user
    pullrequest_comment_tmpl.actor_tmpl = actor_tmpl
    pullrequest_comment_tmpl.user_display_tmpl = actor_display_tmpl
    pullrequest_comment_tmpl.comment = data.comment
    pullrequest_comment_tmpl.repo = data.repository
    message = tostring(pullrequest_comment_tmpl)
end

if not message then
    message = 'This is not implemented yet (event ' .. event .. '): ' .. data_
end

ngx.say('message: ', message)

local res, err = tools.send_mattermost_message(
  mattermost_url,
  message,
  username
)

ngx.say(cjson.encode({status='ok'}))
