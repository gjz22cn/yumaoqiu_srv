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
local cipher = require "utils.cipher"
local utils_user = require "utils.user"
local get_current_user = utils_user.get_current_user
local is_login = utils_user.is_login
local m_user = require "model.user"
local localtime = ngx.localtime

local _M = {}

-- 路由匹配
function _M.router(self)
    local routers = {
        POST = {
            ["/wx/user/check"] = function(params)
                local resp_tab = self:user_check(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
        }
    }

    return routers
end

function _M.user_check(self, params)
    local resp = {}

    -- referer检查
    if not waf.wx_referer_check() then
        log.err("不是来自微信小程序的请求")
        ngx.status = ngx.HTTP_FORBIDDEN
        resp.code = '403000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local current_user = get_current_user()
    if not current_user then
        log.err("未登陆")
        ngx.status = ngx.HTTP_FORBIDDEN
        resp.code = '403000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local openid = current_user.openid
    local session_key = current_user.session_key

    -- 取用户信息
    local nick_name = params['nickName']
    local gender = tonumber(params['gender'])
    local language = params['language']
    local city = params['city']
    local province = params['province']
    local country = params['country']
    local avatar_url = params['avatarUrl']
    local signature = params['signature']
    local encrypted_data = params['encryptedData']
    local iv = params['iv']
    local rawData = params['rawData']

    log.debug("微信用户信息: ", params.__body)

    -- 签名
    local ok = cipher.verify_sha1_sign(rawData .. session_key, signature)
    if not ok then
        log.err("签名验证未通过")
        resp.code = '600003'
        resp.msg = response.get_errmsg(resp.code)
        -- 异常登陆, 干掉session
        session.destroy()
        return resp
    end

    -- aes解密
    local decrypted_data = cipher.aes_128_cbc_with_iv_decrypt(session_key, iv, encrypted_data)
    local decrypted_tab = cjson.decode(decrypted_data)
    local union_id = decrypted_tab['unionId']
    local watermark_appid = decrypted_tab['watermark']['appid']
    local appid = config.get('appid')
    if appid ~= watermark_appid then
        log.err("AES解密APPID验证失败")
        resp.code = '600004'
        resp.msg = response.get_errmsg(resp.code)
        -- 异常登陆, 干掉session
        session.destroy()
        return resp
    end

    local now = localtime()

    -- 用户信息插入数据库
    local user_info_tab = {
        openid=openid, nick_name=nick_name, gender=gender, country=country,
        province=province, city=city, avatar_url=avatar_url, union_id=union_id or "",
        appid=appid, addtime=now, logintime=now
    }

    local res = m_user.query(openid)
    if u_table.is_empty(res) then
        m_user.insert(user_info_tab)
    else
        m_user.update(user_info_tab)
    end

    resp = {resp_code='000000', resp_msg=response.get_errmsg('000000')}
    return resp
end

return _M
