local ngx_re = require "ngx.re"
local ngx_var = ngx.var
local config = require "config"
local log = require "utils.log"


local _M = {}


function _M.wx_referer_check()
    -- dev环境不做检查
    local env = os.getenv('environment')
    if env == 'dev' then
        return true
    end

    -- referer检查
    local http_referer = ngx_var.http_referer
    log.debug("referer: ", http_referer)
    local res, err = ngx_re.split(http_referer, "/")
    if not res then
        log.err("ngx.re.split error: ", err)
        return false
    end
    local host, appid = res[3], res[4]
    if host ~= config.get('wx_app_host') or appid ~= config.get('appid') then
        return false
    end

    return true
end


return _M
