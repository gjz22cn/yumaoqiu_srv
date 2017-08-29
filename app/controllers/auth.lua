local config = require "config"
local cjson = require "cjson"
local http = require "utils.http"
local session = require "utils.session"
local constant = require "utils.constant"
local waf = require "utils.waf"
local u_table = require "utils.table"
local log = require "utils.log"
local response = require "utils.response"
local resp_send = response.send

local _M = {}

-- 路由匹配
function _M.router(self)
    local routers = {
        POST = {
            ["/wx/auth/login"] = function(params)
                local resp_tab = self:login(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
        }
    }

    return routers
end

-- 登陆
function _M.login(self, params)
    local resp = {}

    -- referer检查
    if not waf.wx_referer_check() then
        log.err("不是来自微信小程序的请求")
        ngx.status = ngx.HTTP_FORBIDDEN
        resp.code = '403000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 取微信小程序发来的code
    local code = params['code']

    if not code then
        log.err("code为空, 登录失败")
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 访问微信服务获取openid+session_key
    local appid = config.get('appid')
    local secret = config.get('secret')

    local req_body_tab = {
        appid = appid,
        secret = secret,
        js_code = code,
        grant_type = 'authorization_code'
    }

    local res_body = http.post(constant.URL.WX_CODE2SESSION, req_body_tab)
    local res_body_tab = cjson.decode(res_body)
    if u_table.is_empty(res_body_tab) then
        log.err("请求微信小程序获取session失败, 登录失败")
        resp.code = '600001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local openid = res_body_tab.openid
    local session_key = res_body_tab.session_key

    if openid and session_key then
        -- set session
        session.set('__uid', {openid=openid, session_key=session_key})
        -- 微信小程序没有session
        local set_cookie = ngx.header['Set-Cookie']
        local session_id = string.sub(set_cookie, 1, string.find(set_cookie, ';') - 1)
        resp.code = '000000'
        resp.msg = response.get_errmsg(resp.code)
        resp.session = session_id
        return resp
    else
        log.err("登录失败: 微信返回的openid session_key为空")
        resp.code = '600002'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end
end

return _M
