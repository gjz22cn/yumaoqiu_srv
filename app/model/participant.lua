local db = require "utils.db"
local log = require "utils.log"
local tab_insert = table.insert


local _M = {}

function _M.insert(db_trans, participant_tab)
    local sql = "INSERT INTO participant (gameId, openId, name, phone, comment, addtime) " ..
                "VALUES (%d, %s, %s, %s, %s, %s)"

    local params = {}
    tab_insert(params, participant_tab.game_id)
    tab_insert(params, participant_tab.openid)
    tab_insert(params, participant_tab.name)
    tab_insert(params, participant_tab.phone)
    tab_insert(params, participant_tab.comment)
    tab_insert(params, participant_tab.addtime)

    local ok, errno = db_trans:insert(sql, params)
    if not ok then
        log.err("报名信息插入数据库失败")
    end

    return ok
end

function _M.delete(db_trans, openid, game_id)
    local sql = "DELETE FROM participant WHERE gameId=%d and openId=%s"

    local params = {}
    tab_insert(params, game_id)
    tab_insert(params, openid)

    local ok, errno = db_trans:delete(sql, params)
    if not ok then
        log.err("取消报名失败")
    end

    return ok
end

function _M.update_participant_num(db_trans, game_tab)
    local sql = "UPDATE game SET participantNum=participantNum+1 " ..
                "WHERE id=%d AND deleted=0 AND (participantNum<limitNum OR limitNum=-1) AND deadline>=%s"

    local params = {}
    tab_insert(params, game_tab.id)
    tab_insert(params, string.sub(game_tab.now, 1, 10))

    local ok, errno = db_trans:update(sql, params)
    if not ok then
        log.err("报名人数更新失败")
    end

    return ok
end

function _M.delete_participant_num(db_trans, id, now)
    local sql = "UPDATE game SET participantNum=participantNum-1 WHERE id=%d AND deleted=0 AND deadline>=%s"

    local params = {}
    tab_insert(params, id)
    tab_insert(params, string.sub(now, 1, 10))

    local ok, errno = db_trans:update(sql, params)
    if not ok then
        log.err("报名人数更新失败")
    end

    return ok
end


return _M
