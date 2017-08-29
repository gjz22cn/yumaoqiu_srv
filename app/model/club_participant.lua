local db = require "utils.db"
local log = require "utils.log"
local tab_insert = table.insert


local _M = {}

function _M.insert(db_trans, participant_tab)
    local sql = "INSERT INTO clubParticipant (gameId, openId, name, phone, comment, participantNum, addtime) " ..
                "VALUES (%d, %s, %s, %s, %s, %d, %s)"

    local params = {}
    tab_insert(params, participant_tab.game_id)
    tab_insert(params, participant_tab.openid)
    tab_insert(params, participant_tab.name)
    tab_insert(params, participant_tab.phone)
    tab_insert(params, participant_tab.comment)
    tab_insert(params, participant_tab.num)
    tab_insert(params, participant_tab.addtime)

    local ok, errno = db_trans:insert(sql, params)
    if not ok then
        log.err("报名信息插入数据库失败")
    end

    return ok
end

function _M.delete(db_trans, openid, game_id)
    local sql = "DELETE FROM clubParticipant WHERE gameId=%d and openId=%s"

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
    local sql = "UPDATE game SET participantNum=participantNum+%d " ..
                "WHERE id=%d AND deleted=0 AND (participantNum+%d<=limitNum OR limitNum=-1) AND deadline>=%s and gameType=7"

    local params = {}
    tab_insert(params, game_tab.num)
    tab_insert(params, game_tab.id)
    tab_insert(params, game_tab.num)
    tab_insert(params, string.sub(game_tab.now, 1, 10))

    local ok, errno = db_trans:update(sql, params)
    if not ok then
        log.err("报名人数更新失败")
    end

    return ok
end

function _M.delete_participant_num(db_trans, id, now, openid)
    local sql = "UPDATE game SET participantNum=participantNum-(SELECT participantNum from clubParticipant where gameId=%d and openId=%s) " ..
                "WHERE id=%d AND deleted=0 AND deadline>=%s and gameType=7"

    local params = {}
    tab_insert(params, id)
    tab_insert(params, openid)
    tab_insert(params, id)
    tab_insert(params, string.sub(now, 1, 10))

    local ok, errno = db_trans:update(sql, params)
    if not ok then
        log.err("报名人数更新失败")
    end

    return ok
end


function _M.query_num(game_id)
    local sql = "SELECT openId, name, participantNum FROM clubParticipant WHERE gameId=%d ORDER BY addtime"

    local params = {game_id}
    return db.select(sql, params)
end


return _M
