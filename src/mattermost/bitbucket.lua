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
local commit_comment_tmpl = template.new([[
{* actor_tmpl *} **[{* repo.full_name *}]({* repo.links.html.href *})**/*[{* comment.commit.hash *}]({* comment.commit.links.html.href *})* :: [New comment]({* comment.links.html.href *}) from [{* comment.user.display_name *}]({* comment.user.links.html.href *}):
```
{* comment.content.raw *}
```
]])
commit_comment_tmpl.actor_tmpl = actor_tmpl
local pullrequest_comment_tmpl = template.new([[
'{* actor_tmpl *} **[{* repo.full_name *}]({* repo.links.html.href *})**/*[PR {* comment.pullrequest.title *}]({* comment.pullrequest.links.html.href *})* :: [New comment]({* comment.links.html.href *}) from [{* comment.user.display_name *}]({* comment.user.links.html.href *}):
```
{* comment.content.raw *}
```
]])
pullrequest_comment_tmpl.actor_tmpl = actor_tmpl

if data.actor then
    actor_tmpl.actor = data.actor
end

local push = data.push
if push then
    actor_display_tmpl.actor = data.actor
    push_tmpl.repo = data.repository
    push_tmpl.new_commit = push.changes[1].new
    message = tostring(push_tmpl)
end

local pullrequest = data.pullrequest
if pullrequest then
    actor_display_tmpl.actor = data.actor
    pullrequest_tmpl.pullrequest = pullrequest
    pullrequest_tmpl.repo = pullrequest.destination.repository
    message = tostring(pullrequest_tmpl)
end

local comment = data.comment
if comment then
    -- now question is whether the comment is for pull request or for commit
    if comment.commit then
        commit_comment_tmpl.comment = comment
        commit_comment_tmpl.repo = data.repository
        message = tostring(commit_comment_tmpl)
    end

    if comment.pullrequest then
        pullrequest_comment_tmpl.comment = comment
        pullrequest_comment_tmpl.repo = data.repository
        message = tostring(pullrequest_comment_tmpl)
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
