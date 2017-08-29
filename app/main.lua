local router = require "resty.router"
local r = router.new()

local routers = require "routers"
local common = require "utils.common"

local log = require "utils.log"
local response = require "utils.response"
local resp_send = response.send

local req = ngx.req
local var = ngx.var

local _M = {}

function _M.run()
    req.set_header("User-Agent", "Mozilla/5.0 (Windows NT 6.1; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/53.0.2785.143 Safari/537.36 appservice webview/100000http")
    ngx.req.read_body()
    r:match(routers.get_routers())

    local status, ok, errmsg = pcall(function()
        return r:execute(
            req.get_method(),
            var.uri,
            req.get_uri_args(),
            req.get_post_args(),
            {__body=req.get_body_data()})
    end)

    if status then
        if ok then
            -- ngx.status = 200
        else
            ngx.status = 404
            resp_send("Not Found")
            log.err(errmsg)
        end
    else
        ngx.status = 500
        resp_send("Internal Server Error")
        log.err(ok)
    end
end

return _M
