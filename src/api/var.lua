local hex_to_char = function(x)
  return string.char(tonumber(x, 16))
end

local unescape = function(url)
  if not url then
    return nil
  end
  return url:gsub("%%(%x%x)", hex_to_char)
end

ngx.say(string.format('Call me with ?a=<value>. Called with "%s"', unescape(ngx.var.arg_a)))
