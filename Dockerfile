FROM openresty/openresty:latest-xenial
MAINTAINER Przemek <cgenie@gmail.com>

RUN /usr/local/openresty/luajit/bin/luarocks install lua-resty-http
