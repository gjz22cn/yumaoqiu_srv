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
local m_knockout = require "model.knockout"
local m_club_participant = require "model.club_participant"
local localtime = ngx.localtime
local multipart = require "utils.multipart"
local str_sub = string.sub
local ngx_var = ngx.var
local ngx_re = require "ngx.re"

-- cjson.encode_empty_table_as_object(false)

local _M = {}

-- 路由匹配
function _M.router(self)
    local routers = {
        POST = {
            ["/wx/knockout/create"] = function(params)
                local resp_tab = self:create(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/knockout/update"] = function(params)
                local resp_tab = self:update(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/knockout/delete"] = function(params)
                local resp_tab = self:delete(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/knockout/query"] = function(params)
                local resp_tab = self:query(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/knockout/list"] = function(params)
                local resp_tab = self:list(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/knockout/list2"] = function(params)
                local resp_tab = self:list2(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
        }
    }

    return routers
end

function _M.create(self, params)
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
    local game_event = tonumber(params.gameEvent)
    local rounds = params.rounds
    local participant = params.participant
    local participant2 = params.participant2
    local game_date = params.gameDate
    local begin_time = params.beginTime
    local end_time = params.endTime
    local address = params.address
    local score = tonumber(params.score) or 0
    local score2 = tonumber(params.score2) or 0

    -- 参数校验
    if not game_id or not game_event or not rounds or not participant or
        not participant2 or not game_date or not begin_time or not end_time or
        not address or score < 0 or score2 < 0 or not constant.TEAM_TYPE[game_event] then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- openid 和 game_id校验
    local game_info = m_game.query_by_userid_gameid(openid, game_id)
    if u_table.is_empty(game_info) then
        log.err("无权限")
        ngx.status = ngx.HTTP_FORBIDDEN
        resp.code = '403000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 插入数据库
    local knockout_tab = {
        game_id=game_id, game_event=game_event, rounds=rounds, participant=participant,
        participant2=participant2, game_date=game_date, begin_time=begin_time, end_time=end_time,
        address=address, score=score, score2=score2, addtime=localtime()
    }

    local ok = m_knockout.insert(knockout_tab)
    if not ok then
        resp.code = '600301'
    else
        resp.code = '000000'
    end
    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.update(self, params)
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
    local id = tonumber(params.id)
    local game_id = tonumber(params.gameId)
    local game_event = tonumber(params.gameEvent)
    local rounds = params.rounds
    local participant = params.participant
    local participant2 = params.participant2
    local game_date = params.gameDate
    local begin_time = params.beginTime
    local end_time = params.endTime
    local address = params.address
    local score = tonumber(params.score) or 0
    local score2 = tonumber(params.score2) or 0

    -- 冠军亚军季军
    local champion = params.champion or ""
    local second = params.second or ""
    local third = params.third or ""

    -- 参数校验
    if not id or not game_id or not game_event or not rounds or not participant or
        not participant2 or not game_date or not begin_time or not end_time or
        not address or score < 0 or score2 < 0 or not constant.TEAM_TYPE[game_event] then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- openid 和 game_id校验
    local game_info = m_game.query_by_userid_gameid(openid, game_id)
    if u_table.is_empty(game_info) then
        log.err("无权限")
        ngx.status = ngx.HTTP_FORBIDDEN
        resp.code = '403000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 插入数据库
    local knockout_tab = {
        id=id, game_event=game_event, rounds=rounds, participant=participant,
        participant2=participant2, game_date=game_date, begin_time=begin_time, end_time=end_time,
        address=address, score=score, score2=score2, addtime=localtime()
    }

    local ok = m_knockout.update(knockout_tab)
    if not ok then
        resp.code = '600302'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 冠军 亚军 季军更新
    if champion ~= "" or second ~= "" or third ~= "" then
        ok = m_game.update_champion(game_id, champion, second, third)
    end
    if not ok then
        resp.code = '600302'
    else
        resp.code = '000000'
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.delete(self, params)
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
    local id = tonumber(params.id)
    local game_id = tonumber(params.gameId)

    -- 参数校验
    if not id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- openid 和 game_id校验
    local game_info = m_game.query_by_userid_gameid(openid, game_id)
    if u_table.is_empty(game_info) then
        log.err("无权限")
        ngx.status = ngx.HTTP_FORBIDDEN
        resp.code = '403000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 更新数据库
    local knockout_tab = {
        id=id
    }

    local ok = m_knockout.delete(knockout_tab)
    if not ok then
        resp.code = '600303'
    else
        resp.code = '000000'
    end
    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.query(self, params)
    local resp = {}
    resp.result = {}

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
    local id = tonumber(params.id)

    if not id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 查询数据库
    res = m_knockout.query(id)
    if u_table.is_empty(res) then
        resp.result.data = {}
    else
        resp.result.data = res[1]
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    return resp
end



function _M.list(self, params)
    local resp = {}
    resp.result = {}

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

    if not game_id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 查询数据库
    res = m_knockout.list(game_id)
    if u_table.is_empty(res) then
        resp.result.data = {}
    else
        resp.result.data = res
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.list2(self, params)
    local resp = {}
    resp.result = {}

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

    if not game_id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local now = localtime()

    -- 查询数据库
    res = m_knockout.list(game_id)
    if u_table.is_empty(res) then
        resp.result.data = {}
    else
        local res_sort = {}
        for _, v in ipairs(res) do
            if now < v.gameDate .. ' ' .. v.beginTime then
                v.progress = "未开始"
            elseif now > v.gameDate .. ' ' .. v.endTime and (v.score > 0 or v.score2 > 0) then
                v.progress = "已结束"
            else
                v.progress = "进行中"
            end

            if res_sort[v.rounds] then
                table.insert(res_sort[v.rounds], v)
            else
                res_sort[v.rounds] = {v}
            end
        end

        resp.result.data = res_sort
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    return resp
end


return _M
