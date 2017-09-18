local db = require "utils.db"
local log = require "utils.log"
local tab_insert = table.insert
local tab_concat = table.concat


local _M = {}

function _M.insert(game_tab)
    local sql = "INSERT INTO game (openId, gameType, gameName, teamType, beginTime, endTime, deadline, address, limitNum, " ..
                "pic, creator, creatorPhone, addtime, comment) VALUES (%s, %d, %s, %s, %s, %s, %s, %s, %d, %s, %s, %s, %s, %s)"

    local params = {}
    tab_insert(params, game_tab.openid)
    tab_insert(params, game_tab.game_type)
    tab_insert(params, game_tab.game_name)
    tab_insert(params, game_tab.team_type)
    tab_insert(params, game_tab.begin_time)
    tab_insert(params, game_tab.end_time)
    tab_insert(params, game_tab.deadline)
    tab_insert(params, game_tab.address)
    tab_insert(params, game_tab.limit_num)
    tab_insert(params, game_tab.pic)
    tab_insert(params, game_tab.creator)
    tab_insert(params, game_tab.creator_phone)
    tab_insert(params, game_tab.addtime)
    tab_insert(params, game_tab.comment)

    local ok, errno = db.insert(sql, params)
    if not ok then
        log.err("比赛信息插入数据库失败")
    end

    return ok
end


function _M.update(game_tab)
    local sql = "UPDATE game SET gameType=%d, gameName=%s, teamType=%s, beginTime=%s, endTime=%s, deadline=%s, " ..
                "address=%s, limitNum=%d, pic=%s, creator=%s, creatorPhone=%s, addtime=%s, comment=%s WHERE id=%d AND openId=%s"

    local params = {}
    tab_insert(params, game_tab.game_type)
    tab_insert(params, game_tab.game_name)
    tab_insert(params, game_tab.team_type)
    tab_insert(params, game_tab.begin_time)
    tab_insert(params, game_tab.end_time)
    tab_insert(params, game_tab.deadline)
    tab_insert(params, game_tab.address)
    tab_insert(params, game_tab.limit_num)
    tab_insert(params, game_tab.pic)
    tab_insert(params, game_tab.creator)
    tab_insert(params, game_tab.creator_phone)
    tab_insert(params, game_tab.addtime)
    tab_insert(params, game_tab.comment)
    tab_insert(params, game_tab.id)
    tab_insert(params, game_tab.openid)

    local ok, errno = db.update(sql, params)
    if not ok then
        log.err("比赛信息更新失败")
    end

    return ok
end


function _M.update_champion(id, champion, second, third)
    log.debug(champion)
    log.debug(second)
    log.debug(third)

    local sql = "UPDATE game SET "

    local tmp = {}
    local params = {}

    if champion ~= "" then
        tab_insert(tmp, "champion=%s")
        tab_insert(params, champion)
    end
    if second ~= "" then
        tab_insert(tmp, "second=%s")
        tab_insert(params, second)
    end
    if third ~= "" then
        tab_insert(tmp, "third=%s")
        tab_insert(params, third)
    end

    sql = sql .. tab_concat(tmp, ", ") .. " WHERE id=%d"

    tab_insert(params, id)

    local ok, errno = db.update(sql, params)
    if not ok then
        log.err("比赛信息更新失败")
    end

    return ok
end


function _M.delete(game_tab)
    local sql = "UPDATE game SET deleted=1 WHERE id=%d AND openId=%s"

    local params = {}
    tab_insert(params, game_tab.id)
    tab_insert(params, game_tab.openid)

    local ok, errno = db.update(sql, params)
    if not ok then
        log.err("比赛信息删除失败")
    end

    return ok
end


function _M.game_query(openid, page_num, per_page)
    local sql = "SELECT * FROM game WHERE openId=%s AND gameType!=7 AND deleted=0 ORDER BY addtime DESC LIMIT %d, %d"

    local params = {openid, (page_num-1)*per_page, per_page}

    return db.select(sql, params)
end


function _M.game_count(openid)
    local sql = "SELECT count(*) as total FROM game WHERE openId=%s AND gameType!=7 AND deleted=0"

    local params = {openid}
    return db.select(sql, params)
end

function _M.list(order_type, page_num, per_page)
    local sql = nil
    if order_type == 'progress' then
        sql = "SELECT * FROM game WHERE gameType!=7 AND deleted=0 ORDER BY progress, beginTime DESC LIMIT %d, %d"
    elseif order_type == 'heat' then
        sql = "SELECT * FROM game WHERE gameType!=7 AND deleted=0 ORDER BY participantNum DESC LIMIT %d, %d"
    else
        sql = "SELECT * FROM game WHERE gameType!=7 AND deleted=0 ORDER BY beginTime DESC LIMIT %d, %d"
    end

    local params = {(page_num-1)*per_page, per_page}

    return db.select(sql, params)
end

function _M.count()
    local sql = "SELECT count(*) as total FROM game WHERE gameType!=7 AND deleted=0"

    return db.select(sql, nil)
end

function _M.list_by_progress(progress, page_num, per_page)
    local sql = "SELECT * FROM game WHERE gameType!=7 AND deleted=0 AND progress=%d ORDER BY beginTime DESC LIMIT %d, %d"

    local params = {progress, (page_num-1)*per_page, per_page}

    return db.select(sql, params)
end

function _M.count_by_progress(progress)
    local sql = "SELECT count(*) as total FROM game WHERE gameType!=7 AND deleted=0 AND progress=%d"

    local params = {progress}

    return db.select(sql, params)
end

function _M.participant_game_query(openid, page_num, per_page)
    local sql = "SELECT * FROM game WHERE id IN (SELECT gameId FROM participant WHERE openId=%s) AND deleted=0 " ..
                "ORDER BY progress, beginTime DESC LIMIT %d, %d"

    local params = {openid, (page_num-1)*per_page, per_page}

    return db.select(sql, params)
end


function _M.participant_game_count(openid)
    local sql = "SELECT count(*) as total FROM game WHERE id IN (SELECT gameId FROM participant WHERE openId=%s) AND deleted=0 " ..
                "ORDER BY progress, beginTime DESC"

    local params = {openid}
    return db.select(sql, params)
end


function _M.club_query(openid, page_num, per_page)
    local sql = "SELECT * FROM game WHERE openId=%s AND gameType=7 AND deleted=0 ORDER BY addtime DESC LIMIT %d, %d"

    local params = {openid, (page_num-1)*per_page, per_page}

    return db.select(sql, params)
end


function _M.club_count(openid)
    local sql = "SELECT count(*) as total FROM game WHERE openId=%s AND gameType=7 AND deleted=0"

    local params = {openid}
    return db.select(sql, params)
end


function _M.participant_club_query(openid, page_num, per_page)
    local sql = "SELECT * FROM game WHERE id IN (SELECT gameId FROM clubParticipant WHERE openId=%s) AND deleted=0 " ..
                "ORDER BY progress, beginTime DESC LIMIT %d, %d"

    local params = {openid, (page_num-1)*per_page, per_page}

    return db.select(sql, params)
end


function _M.participant_club_count(openid)
    local sql = "SELECT count(*) as total FROM game WHERE id IN (SELECT gameId FROM clubParticipant WHERE openId=%s) AND deleted=0 " ..
                "ORDER BY progress, beginTime DESC"

    local params = {openid}
    return db.select(sql, params)
end


function _M.num_query(game_id)
    local sql = "SELECT limitNum, participantNum FROM game WHERE id=%d"

    local params = {game_id}

    return db.select(sql, params)
end

function _M.query_by_userid_gameid(openid, game_id)
    local sql = "SELECT * FROM game WHERE id=%d AND openId=%s"

    local params = {game_id, openid}

    return db.select(sql, params)
end

function _M.query_by_id(game_id)
    local sql = "SELECT * FROM game WHERE id=%d LIMIT 1"

    local params = {game_id}

    return db.select(sql, params)
end

function _M.update_progress(now)
    now = string.sub(now, 1, 10)
    local sql = "UPDATE game SET progress=2 WHERE progress=1 AND endTime>=%s AND beginTime<=%s"

    local ok, errno = db.update(sql, {now, now})
    --if not ok then
    --    log.err("比赛进程更新失败")
    --end

    sql = "UPDATE game SET progress=3 WHERE progress in (1, 2) AND endTime<%s"

    ok, errno = db.update(sql, {now})
    --if not ok then
    --    log.err("比赛进程更新失败")
    --end
end

return _M
