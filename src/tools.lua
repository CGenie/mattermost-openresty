local mymodule = {}

local cjson = require "cjson"
local http = require "resty.http"
local hc = http:new()

function mymodule.get_ngx_data()
  ngx.req.read_body()
  local data = ngx.req.get_body_data()
  if not data then
    local fpath = ngx.req.get_body_file()
    local f = io.open(fpath, 'r')
    data = f:read()
    f:close()
  end

  return data
end

function mymodule.send_mattermost_message(url, text, username)
  local data = {text=message}
  if username then
    data.username = username
  end

  local body = cjson.encode(data)

  local res, err = hc:request_uri(
    url, {
      method="POST",
      body=body,
      headers = {
        ["Content-Type"] = "application/json",
      },
      ssl_verify=false
  })

  return res, err
end

return mymodule
