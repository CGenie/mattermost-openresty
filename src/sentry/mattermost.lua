-- curl -i -X POST -d 'payload={"text": "Hello, this is some text.\nThis is more text."}' http://yourmattermost.com/hooks/xxx-generatedkey-xxx

local cjson = require "cjson"
local http = require "resty.http"
local hc = http:new()

local mattermost_url = os.getenv("SENTRY_MATTERMOST_URL")
if not mattermost_url then
    ngx.say("SENTRY_MATTERMOST_URL env variable not defined")
    return
end
local username = os.getenv("SENTRY_MATTERMOST_USER")
if not username then
    username = 'sentry'
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
local message = '**' .. data.project_name .. '** :: ' .. data.level .. ' :: [' .. data.message .. '](' .. data.url .. ')'

ngx.say('message: ', message)

--local body = 'payload=' .. cjson.encode({text=message})
--local body = cjson.encode({payload={text=message}})
local body = cjson.encode({text=message, username=username})

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
