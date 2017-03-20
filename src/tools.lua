local mymodule = {}

local cjson = require "cjson"
local http = require "resty.http"

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

function mymodule.get_env_variable_with_arg(base_variable_name, arg_name, default)
    local ngx_var = ngx.var["arg_" .. arg_name]
    local variable_name = base_variable_name
    local variable_env = nil
    local base_var = os.getenv(base_variable_name)

    -- Try to parse base_variable_name as a JSON string and pull variable from there
    if base_var then
        local status, ret = pcall(function() return cjson.decode(base_var) end)
        local value = ret[ngx_var] or ret['default']
        if status and value then
            return value
        end
    end

    if ngx_var then
        variable_name = variable_name .. "_" .. ngx_var:upper()
    end
    variable_env = os.getenv(variable_name)
    if variable_env then
        return variable_env
    end

    if default then
        return default
    end

    ngx.log(ngx.ERR, base_variable_name .. " not defined")
    if base_variable_name ~= variable_name then
        ngx.log(ngx.ERR, variable_name .. " not defined")
    end
    if base_var then
        ngx.log(ngx.ERR, "Key " .. ngx_var .. " not present in JSON " .. base_var)
    end
    ngx.log(ngx.ERR, "Default not defined")
    ngx.exit(500)
end

function mymodule.send_mattermost_message(url, text, username)
    local hc = http:new()
    local data = {text=text}
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

    ngx.say("\n\nsent body:\n", body)

    return res, err
end

return mymodule
