local db = require "utils.db"
local log = require "utils.log"
local tab_insert = table.insert


local _M = {}

function _M.insert(knockout_tab)
    local sql = "INSERT INTO knockout (gameId, gameEvent, rounds, participant, participant2, gameDate, beginTime, " ..
                "endTime, score, score2, address, addtime) VALUES (%d, %d, %s, %s, %s, %s, %s, %s, %d, %d, %s, %s)"

    local params = {}
    tab_insert(params, knockout_tab.game_id)
    tab_insert(params, knockout_tab.game_event)
    tab_insert(params, knockout_tab.rounds)
    tab_insert(params, knockout_tab.participant)
    tab_insert(params, knockout_tab.participant2)
    tab_insert(params, knockout_tab.game_date)
    tab_insert(params, knockout_tab.begin_time)
    tab_insert(params, knockout_tab.end_time)
    tab_insert(params, knockout_tab.score)
    tab_insert(params, knockout_tab.score2)
    tab_insert(params, knockout_tab.address)
    tab_insert(params, knockout_tab.addtime)

    local ok, errno = db.insert(sql, params)
    if not ok then
        log.err("赛程信息插入数据库失败")
    end

    return ok
end


function _M.update(knockout_tab)
    local sql = "UPDATE knockout SET gameEvent=%d, rounds=%s, participant=%s, participant2=%s, " ..
                "gameDate=%s, beginTime=%s, endTime=%s, score=%d, score2=%d, address=%s WHERE id=%d"

    local params = {}
    tab_insert(params, knockout_tab.game_event)
    tab_insert(params, knockout_tab.rounds)
    tab_insert(params, knockout_tab.participant)
    tab_insert(params, knockout_tab.participant2)
    tab_insert(params, knockout_tab.game_date)
    tab_insert(params, knockout_tab.begin_time)
    tab_insert(params, knockout_tab.end_time)
    tab_insert(params, knockout_tab.score)
    tab_insert(params, knockout_tab.score2)
    tab_insert(params, knockout_tab.address)
    tab_insert(params, knockout_tab.id)

    local ok, errno = db.update(sql, params)
    if not ok then
        log.err("赛程信息更新失败")
    end

    return ok
end


function _M.delete(knockout_tab)
    local sql = "DELETE FROM knockout WHERE id=%d"

    local params = {}
    tab_insert(params, knockout_tab.id)

    local ok, errno = db.delete(sql, params)
    if not ok then
        log.err("赛程信息删除失败")
    end

    return ok
end


function _M.query(id)
    local sql = "SELECT knockout.*, game.champion, game.second, game.third FROM knockout, game where knockout.id=%d AND knockout.gameId=game.id LIMIT 1"

    local params = {id}

    return db.select(sql, params)
end

function _M.list(game_id)
    local sql = "SELECT * FROM knockout WHERE gameId=%d"

    local params = {game_id}

    return db.select(sql, params)
end


return _M
