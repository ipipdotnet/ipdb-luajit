# lua-resty-ipdb

## Installing
<pre>
    git clone https://github.com/ipipdotnet/ipdb-luajit
    cd ipdb-luajit
    cp ipdb/* /usr/local/openresty/lualib/resty/
</pre>
## Nginx.conf
<pre>
user  frk;
worker_processes  1;
events {
    worker_connections  1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile        on;
    keepalive_timeout  65;

    init_by_lua_block {
        local city = require("resty.ipdb.city")
        ipdb = city:new("/home/frk/city.free.ipdb")
        cjson = require("cjson")
    }

    server {
        listen 8080;

        location / {
            default_type application/json;
            content_by_lua '
                local args = ngx.req.get_uri_args();
	            local loc = ipdb:find(args["ip"], "CN");
                ngx.say(cjson.encode(loc));
            ';
        }
    }
}
</pre>