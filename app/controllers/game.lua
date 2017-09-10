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

cjson.encode_empty_table_as_object(false)

local _M = {}

-- 路由匹配
function _M.router(self)
    local routers = {
        POST = {
            ["/wx/game/create"] = function(params)
                local resp_tab = self:create(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/update"] = function(params)
                local resp_tab = self:update(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/delete"] = function(params)
                local resp_tab = self:delete(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/list"] = function(params)
                local resp_tab = self:list(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/list_by_progress"] = function(params)
                local resp_tab = self:list_by_progress(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/query_by_id"] = function(params)
                local resp_tab = self:query_by_id(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/creator/query"] = function(params)
                local resp_tab = self:creator_game_query(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/participant/query"] = function(params)
                local resp_tab = self:participant_game_query(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/club/creator/query"] = function(params)
                local resp_tab = self:creator_club_query(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/club/participant/query"] = function(params)
                local resp_tab = self:participant_club_query(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/club/participant/query_num"] = function(params)
                local resp_tab = self:participant_club_query_num(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/participant/query_num"] = function(params)
                local resp_tab = self:participant_game_query_num(params)
                local resp = cjson.encode(resp_tab)
                resp_send(resp)
            end,
            ["/wx/game/participant_num"] = function(params)
                local resp_tab = self:participant_num(params)
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
    local res = nil
    if str_sub(ngx_var.content_type, 1, 19) == "multipart/form-data" then
        res = multipart.parser(params.__body, config.get('pic_dir'))
        if res.filenames then
            res.filenames = res.filenames[1]
        else
            res.filenames = ""
        end
    else
        res = params
        res.filenames = ""
    end

    if u_table.is_empty(res) then
        log.err("multipart/form-data解析异常")
        resp.code = '400000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local game_type = tonumber(res.gameType)
    local game_name = res.gameName
    local team_type = res.teamType
    local begin_time = res.beginTime
    local end_time = res.endTime
    local deadline = res.deadline
    local address = res.address
    local limit_num = tonumber(res.limitNum)
    local creator = res.creator
    local creator_phone = res.creatorPhone

    -- 参数校验
    local team_type_list = nil
    if team_type then
        team_type_list, err = ngx_re.split(team_type, ",")
        for i, t in ipairs(team_type_list) do
            if not constant.TEAM_TYPE[tonumber(t)] then
                team_type_list = nil
                break
            end
        end
    end

    if game_type ~= 6 then
        team_type = ''
        team_type_list = nil
    end

    if not game_type or not game_name or not begin_time or not end_time or not deadline or
        not address or not limit_num or not creator or not creator_phone or
        not constant.GAME_TYPE[game_type] or (game_type == 6 and not team_type_list) or
        not res.filenames then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 插入数据库
    local game_tab = {
        openid=openid, game_type=game_type, game_name=game_name, team_type=team_type, begin_time=begin_time,
        end_time=end_time, deadline=deadline, address=address, limit_num=limit_num,
        pic=res.filenames, creator=creator, creator_phone=creator_phone, addtime=localtime()
    }

    local ok = m_game.insert(game_tab)
    if not ok then
        resp.code = '600101'
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
    local res = nil
    if str_sub(ngx_var.content_type, 1, 19) == "multipart/form-data" then
        res = multipart.parser(params.__body, config.get('pic_dir'))
        if res.filenames then
            res.filenames = res.filenames[1]
        else
            res.filenames = ""
        end
    else
        res = params
        res.filenames = ""
    end

    if u_table.is_empty(res) then
        log.err("multipart/form-data解析异常")
        resp.code = '400000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local id = tonumber(res.id)
    local game_type = tonumber(res.gameType)
    local game_name = res.gameName
    local team_type = res.teamType
    local begin_time = res.beginTime
    local end_time = res.endTime
    local deadline = res.deadline
    local address = res.address
    local limit_num = tonumber(res.limitNum)
    local creator = res.creator
    local creator_phone = res.creatorPhone

    -- 参数校验
    local team_type_list = nil
    if team_type then
        team_type_list, err = ngx_re.split(team_type, ",")
        for i, t in ipairs(team_type_list) do
            if not constant.TEAM_TYPE[tonumber(t)] then
                team_type_list = nil
                break
            end
        end
    end

    if game_type ~= 6 then
        team_type = ''
        team_type_list = nil
    end

    if not game_type or not game_name or not begin_time or not end_time or not deadline or
        not address or not limit_num or not creator or not creator_phone or
        not constant.GAME_TYPE[game_type] or (game_type == 6 and not team_type_list) or
        not res.filenames or not id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 更新数据库
    local game_tab = {
        id=id, openid=openid, game_type=game_type, game_name=game_name, team_type=team_type, begin_time=begin_time,
        end_time=end_time, deadline=deadline, address=address, limit_num=limit_num,
        pic=res.filenames, creator=creator, creator_phone=creator_phone, addtime=localtime()
    }

    local ok = m_game.update(game_tab)
    if not ok then
        resp.code = '600103'
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

    -- 参数校验
    if not id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 更新数据库
    local game_tab = {
        id=id, openid=openid
    }

    local ok = m_game.delete(game_tab)
    if not ok then
        resp.code = '600104'
    else
        resp.code = '000000'
    end
    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.creator_game_query(self, params)
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
    local page_num = tonumber(params.pageNum) or 1
    local per_page = tonumber(params.perPage) or 5

    local res = m_game.game_count(openid)
    if not res then
        resp.code = '600102'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local total = res[1].total
    local total_page = common.get_total_page(total, per_page)

    -- 查询数据库
    res = m_game.game_query(openid, page_num, per_page)
    if not res then
        resp.code = '600102'
    else
        for _, game_tab in ipairs(res) do
            game_tab.progress = constant.GAME_PROGRESS[game_tab.progress]
            game_tab.gameType = constant.GAME_TYPE[game_tab.gameType]
            if game_tab.teamType == "" then
                game_tab.teamType = {}
            else
                game_tab.teamType = ngx_re.split(game_tab.teamType, ",")
                for i, _ in ipairs(game_tab.teamType) do
                    -- game_tab.teamType[i] = constant.GAME_TYPE[tonumber(game_tab.teamType[i])]
                    game_tab.teamType[i] = tonumber(game_tab.teamType[i])
                end
            end
        end

        resp.code = '000000'
        resp.result.data = res
        resp.result.pageNum = page_num
        resp.result.totalPage = total_page
    end

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

    --[[
    local current_user = get_current_user()
    if not current_user then
        log.err("未登陆")
        ngx.status = ngx.HTTP_FORBIDDEN
        resp.code = '403000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local openid = current_user.openid
    ]]

    -- 参数解析
    local page_num = tonumber(params.pageNum) or 1
    local per_page = tonumber(params.perPage) or 5
    local order_type = params.orderType or 'time'

    local res = m_game.count()
    if not res then
        resp.code = '600102'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local total = res[1].total
    local total_page = common.get_total_page(total, per_page)

    -- 查询数据库
    res = m_game.list(order_type, page_num, per_page)
    if not res then
        resp.code = '600102'
    else
        for _, game_tab in ipairs(res) do
            game_tab.progress = constant.GAME_PROGRESS[game_tab.progress]
            game_tab.gameType = constant.GAME_TYPE[game_tab.gameType]
            if game_tab.teamType == "" then
                game_tab.teamType = {}
            else
                game_tab.teamType = ngx_re.split(game_tab.teamType, ",")
                for i, _ in ipairs(game_tab.teamType) do
                    -- game_tab.teamType[i] = constant.GAME_TYPE[tonumber(game_tab.teamType[i])]
                    game_tab.teamType[i] = tonumber(game_tab.teamType[i])
                end
            end
        end

        resp.code = '000000'
        resp.result.data = res
        resp.result.pageNum = page_num
        resp.result.totalPage = total_page
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.list_by_progress(self, params)
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

    --[[
    local current_user = get_current_user()
    if not current_user then
        log.err("未登陆")
        ngx.status = ngx.HTTP_FORBIDDEN
        resp.code = '403000'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local openid = current_user.openid
    ]]

    -- 参数解析
    local page_num = tonumber(params.pageNum) or 1
    local per_page = tonumber(params.perPage) or 5
    local progress = tonumber(params.progress) or 1

    -- 参数校验
    if progress > 3 or progress < 1 then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local res = m_game.count_by_progress(progress)
    if not res then
        resp.code = '600102'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local total = res[1].total
    local total_page = common.get_total_page(total, per_page)

    -- 查询数据库
    res = m_game.list_by_progress(progress, page_num, per_page)
    if not res then
        resp.code = '600102'
    else
        for _, game_tab in ipairs(res) do
            game_tab.progress = constant.GAME_PROGRESS[game_tab.progress]
            game_tab.gameType = constant.GAME_TYPE[game_tab.gameType]
            if game_tab.teamType == "" then
                game_tab.teamType = {}
            else
                game_tab.teamType = ngx_re.split(game_tab.teamType, ",")
                for i, _ in ipairs(game_tab.teamType) do
                    -- game_tab.teamType[i] = constant.GAME_TYPE[tonumber(game_tab.teamType[i])]
                    game_tab.teamType[i] = tonumber(game_tab.teamType[i])
                end
            end
        end

        resp.code = '000000'
        resp.result.data = res
        resp.result.pageNum = page_num
        resp.result.totalPage = total_page
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.query_by_id(self, params)
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

    -- 参数校验
    if not id then
        resp.code = '400001'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    -- 查询数据库
    local res = m_game.query_by_id(id)
    if u_table.is_empty(res) then
        resp.result.data = {}
    else
        for _, game_tab in ipairs(res) do
            game_tab.progress = constant.GAME_PROGRESS[game_tab.progress]
            -- game_tab.gameType = constant.GAME_TYPE[game_tab.gameType]
            if game_tab.teamType == "" then
                game_tab.teamType = {}
            else
                game_tab.teamType = ngx_re.split(game_tab.teamType, ",")
                for i, _ in ipairs(game_tab.teamType) do
                    -- game_tab.teamType[i] = constant.GAME_TYPE[tonumber(game_tab.teamType[i])]
                    game_tab.teamType[i] = tonumber(game_tab.teamType[i])
                end
            end
        end

        resp.result.data = res[1]
    end

    resp.code = '000000'
    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.participant_game_query(self, params)
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
    local page_num = tonumber(params.pageNum) or 1
    local per_page = tonumber(params.perPage) or 5

    local res = m_game.participant_game_count(openid)
    if not res then
        resp.code = '600102'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local total = res[1].total
    local total_page = common.get_total_page(total, per_page)

    -- 查询数据库
    res = m_game.participant_game_query(openid, page_num, per_page)
    if not res then
        resp.code = '600102'
    else
        for _, game_tab in ipairs(res) do
            game_tab.progress = constant.GAME_PROGRESS[game_tab.progress]
            game_tab.gameType = constant.GAME_TYPE[game_tab.gameType]
            if game_tab.teamType == "" then
                game_tab.teamType = {}
            else
                game_tab.teamType = ngx_re.split(game_tab.teamType, ",")
                for i, _ in ipairs(game_tab.teamType) do
                    -- game_tab.teamType[i] = constant.GAME_TYPE[tonumber(game_tab.teamType[i])]
                    game_tab.teamType[i] = tonumber(game_tab.teamType[i])
                end
            end
        end

        resp.code = '000000'
        resp.result.data = res
        resp.result.pageNum = page_num
        resp.result.totalPage = total_page
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.creator_club_query(self, params)
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
    local page_num = tonumber(params.pageNum) or 1
    local per_page = tonumber(params.perPage) or 5

    local res = m_game.club_count(openid)
    if not res then
        resp.code = '600102'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local total = res[1].total
    local total_page = common.get_total_page(total, per_page)

    -- 查询数据库
    res = m_game.club_query(openid, page_num, per_page)
    if not res then
        resp.code = '600102'
    else
        for _, game_tab in ipairs(res) do
            game_tab.progress = constant.GAME_PROGRESS[game_tab.progress]
            game_tab.gameType = constant.GAME_TYPE[game_tab.gameType]
            if game_tab.teamType == "" then
                game_tab.teamType = {}
            else
                game_tab.teamType = ngx_re.split(game_tab.teamType, ",")
                for i, _ in ipairs(game_tab.teamType) do
                    -- game_tab.teamType[i] = constant.GAME_TYPE[tonumber(game_tab.teamType[i])]
                    game_tab.teamType[i] = tonumber(game_tab.teamType[i])
                end
            end
        end

        resp.code = '000000'
        resp.result.data = res
        resp.result.pageNum = page_num
        resp.result.totalPage = total_page
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.participant_club_query(self, params)
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
    local page_num = tonumber(params.pageNum) or 1
    local per_page = tonumber(params.perPage) or 5

    local res = m_game.participant_club_count(openid)
    if not res then
        resp.code = '600102'
        resp.msg = response.get_errmsg(resp.code)
        return resp
    end

    local total = res[1].total
    local total_page = common.get_total_page(total, per_page)

    -- 查询数据库
    res = m_game.participant_club_query(openid, page_num, per_page)
    if not res then
        resp.code = '600102'
    else
        for _, game_tab in ipairs(res) do
            game_tab.progress = constant.GAME_PROGRESS[game_tab.progress]
            game_tab.gameType = constant.GAME_TYPE[game_tab.gameType]
            if game_tab.teamType == "" then
                game_tab.teamType = {}
            else
                game_tab.teamType = ngx_re.split(game_tab.teamType, ",")
                for i, _ in ipairs(game_tab.teamType) do
                    -- game_tab.teamType[i] = constant.GAME_TYPE[tonumber(game_tab.teamType[i])]
                    game_tab.teamType[i] = tonumber(game_tab.teamType[i])
                end
            end
        end

        resp.code = '000000'
        resp.result.data = res
        resp.result.pageNum = page_num
        resp.result.totalPage = total_page
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.participant_club_query_num(self, params)
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
    local res = m_club_participant.query_num(game_id)
    if not res then
        resp.code = '600105'
    else
        resp.code = '000000'
        resp.result.data = res
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end



function _M.participant_game_query_num(self, params)
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
    local res = m_participant.query_num(game_id)
    if not res then
        resp.code = '600105'
    else
        resp.code = '000000'
        resp.result.data = res
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end


function _M.participant_num(self, params)
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
    local res = m_game.num_query(game_id)
    if not res then
        resp.code = '600106'
    else
        resp.code = '000000'
        resp.result.data = res[1]
    end

    resp.msg = response.get_errmsg(resp.code)

    return resp
end


return _M
