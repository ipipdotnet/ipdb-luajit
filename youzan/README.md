# lua-resty-ipdb
for ipdb replace https://github.com/youzan/ngx_http_ipip_module

## Installing
<pre>
    git clone https://github.com/ipipdotnet/ipdb-luajit
    cd ipdb-luajit
    cp -R youzan /usr/local/openresty/lualib/resty/ipdb
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

# "/home/frk/city.free.ipdb" ipdb file path
    init_by_lua_block {
        local city = require("resty.ipdb.city")
        ipdb = city:new("/home/frk/city.ipv4.ipdb")
        cjson = require("cjson")
    }

    server {
        listen 8080;

        location / {
            default_type application/json;
            content_by_lua '
                local args = ngx.req.get_uri_args();
                local loc = ipdb:findArray(args["ip"], "CN");
                local json = {};
                json["ret"] = "ok";
                json["data"] = loc;
                ngx.say(cjson.encode(json));
            ';
        }
    }
}

</pre>