tools = require("tools")

local auth_token = os.getenv("AUTH_TOKEN")
local query_token = ngx.var["arg_auth"]

if auth_token ~= query_token then
    ngx.exit(ngx.HTTP_FORBIDDEN)
end

ngx.exit(ngx.HTTP_OK)
