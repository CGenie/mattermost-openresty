FROM openresty/openresty:alpine-fat
MAINTAINER Przemek <cgenie@gmail.com>

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http
RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-template
