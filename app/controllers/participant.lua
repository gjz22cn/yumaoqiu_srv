local config = require "config"
local cjson = require "cjson"
local http = require "utils.http"
local session = require "utils.session"
local constant = require "utils.constant"
local common = require "utils.common"
local waf = require "utils.waf"
local u_table = require "utils.table"
local log = require "utils.log"
local response = require "utils.response"
local resp_send = response.send
local cipher = require "utils.cipher"
local utils_user = require "utils.user"
local get_current_user = utils_user.get_current_user
local is_login = utils_user.is_login
local m_game = require "model.game"
local m_participant = require "model.participant"
local m_club_participant = require "model.club_participant"
local localtime = ngx.localtime
local multipart = require "utils.multipart"
local str_sub = string.sub
local ngx_var = ngx.var
local ngx_re = require "ngx.re"
local db_trans = require "utils.db_transaction"

cjson.encode_empty_table_as_object(false)

local _M = {}

-- 路由匹配
function _M.router(self)
    local routers = {
        POST = {
            ["/wx/participant/add"] = function(params)
                local resp_tab = self:add(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/participant/cancel"] = function(params)
                local resp_tab = self:cancel(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/clubparticipant/add"] = function(params)
                local resp_tab = self:club_add(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/clubparticipant/cancel"] = function(params)
                local resp_tab = self:club_cancel(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
        }
    }

    return routers
end

function _M.add(self, params)
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

    -- 参数解析
    local game_id = tonumber(params.gameId)
    local name = params.name
    local phone = params.phone or ''
    local comment = params.comment or ''

    -- 参数校验
    if not game_id or not name then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 数据库事务
    local db = db_trans:new()
    if not db then
        log.err("连接数据库异常")
        resp.code = '700001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local ok = db:transaction_start()
    if not ok then
        log.err("开始数据库事务异常")
        resp.code = '700002'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 插入数据库
    local participant_tab = {
        openid=openid, game_id=game_id, name=name, phone=phone,
        comment=comment, addtime=localtime()
    }

    -- 更新报名人数
    local game_tab = {
        id=game_id, now=localtime()
    }

    local ok2 = m_participant.insert(db, participant_tab)
    local ok3 = m_participant.update_participant_num(db, game_tab)
    if not ok2 or not ok3 then
        db:transaction_rollback()
        resp.code = '600201'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    ok = db:transaction_commit()
    if not ok then
        db:transaction_rollback()
        log.err("事务提交失败, 回滚")
        resp.code = '600201'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    return resp
end



function _M.cancel(self, params)
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

    -- 参数解析
    local game_id = tonumber(params.gameId)

    -- 参数校验
    if not game_id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 数据库事务
    local db = db_trans:new()
    if not db then
        log.err("连接数据库异常")
        resp.code = '700001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local ok = db:transaction_start()
    if not ok then
        log.err("开始数据库事务异常")
        resp.code = '700002'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local ok2 = m_participant.delete(db, openid, game_id)
    local ok3 = m_participant.delete_participant_num(db, game_id, localtime())
    if not ok2 or not ok3 then
        db:transaction_rollback()
        resp.code = '600202'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    ok = db:transaction_commit()
    if not ok then
        db:transaction_rollback()
        log.err("事务提交失败, 回滚")
        resp.code = '600202'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    return resp
end



function _M.club_add(self, params)
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

    -- 参数解析
    local game_id = tonumber(params.gameId)
    local name = params.name
    local phone = params.phone or ''
    local comment = params.comment or ''
    local participant_num = tonumber(params.participantNum) or 1

    -- 参数校验
    if not game_id or not name or participant_num < 1 then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 数据库事务
    local db = db_trans:new()
    if not db then
        log.err("连接数据库异常")
        resp.code = '700001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local ok = db:transaction_start()
    if not ok then
        log.err("开始数据库事务异常")
        resp.code = '700002'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 插入数据库
    local participant_tab = {
        openid=openid, game_id=game_id, name=name, phone=phone,
        comment=comment, addtime=localtime(), num=participant_num
    }

    -- 更新报名人数
    local game_tab = {
        id=game_id, now=localtime(), num=participant_num
    }

    local ok2 = m_club_participant.insert(db, participant_tab)
    local ok3 = m_club_participant.update_participant_num(db, game_tab)
    if not ok2 or not ok3 then
        db:transaction_rollback()
        resp.code = '600201'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    ok = db:transaction_commit()
    if not ok then
        db:transaction_rollback()
        log.err("事务提交失败, 回滚")
        resp.code = '600201'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    return resp
end



function _M.club_cancel(self, params)
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

    -- 参数解析
    local game_id = tonumber(params.gameId)

    -- 参数校验
    if not game_id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 数据库事务
    local db = db_trans:new()
    if not db then
        log.err("连接数据库异常")
        resp.code = '700001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local ok = db:transaction_start()
    if not ok then
        log.err("开始数据库事务异常")
        resp.code = '700002'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local ok3 = m_club_participant.delete_participant_num(db, game_id, localtime(), openid)
    local ok2 = m_club_participant.delete(db, openid, game_id)
    if not ok2 or not ok3 then
        db:transaction_rollback()
        resp.code = '600202'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    ok = db:transaction_commit()
    if not ok then
        db:transaction_rollback()
        log.err("事务提交失败, 回滚")
        resp.code = '600202'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    return resp
end


return _M
