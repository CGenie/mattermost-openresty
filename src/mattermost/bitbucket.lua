-- curl -i -X POST -d 'payload={"text": "Hello, this is some text.\nThis is more text."}' http://yourmattermost.com/hooks/xxx-generatedkey-xxx

local cjson = require "cjson"
local http = require "resty.http"
local hc = http:new()

local mattermost_url = os.getenv("BITBUCKET_MATTERMOST_URL")
if not mattermost_url then
    ngx.say("BITBUCKET_MATTERMOST_URL env variable not defined")
    return
end

ngx.req.read_body()
local data_ = ngx.req.get_body_data()
if not data_ then
    local fpath = ngx.req.get_body_file()
    local f = io.open(fpath, 'r')
    data_ = f:read()
    f:close()
end

local data = cjson.decode(data_)
local message = nil

local push = data.push
if push then
    local actor = data.actor.display_name
    local new_commit = push.changes[1].new
    local repo = new_commit.repository.full_name
    local repo_href = new_commit.repository.links.html.href
    local href = new_commit.target.links.html.href
    local name = new_commit.name
    message = '**[' .. repo .. '](' .. href .. ')** :: New commit from ' .. actor .. ': ' .. href .. ' (*' .. name .. '*)'
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

--local body = 'payload=' .. cjson.encode({text=message})
--local body = cjson.encode({payload={text=message}})
local body = cjson.encode({text=message})

local res, err = hc:request_uri(mattermost_url, {
    method="POST",
    body=body,
    headers = {
      ["Content-Type"] = "application/json",
    },
    ssl_verify=false
})

ngx.say(
    "url:\n", mattermost_url,
    --"\n\ndata:\n", data,
    "\n\nsent body:\n", body,
    "\n\nresponse:\n", res.body,
    "\n\nerror:\n", err
)
