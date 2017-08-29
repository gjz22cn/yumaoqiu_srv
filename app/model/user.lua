local db = require "utils.db"
local log = require "utils.log"
local tab_insert = table.insert


local _M = {}

function _M.insert(user_tab)
    local sql = "INSERT INTO users(openId, nickName, gender, country, province, city, avatarUrl, unionId, " ..
                "appId, addtime, logintime) VALUES(%s, %s, %d, %s, %s, %s, %s, %s, %s, %s, %s)"

    local params = {}
    tab_insert(params, user_tab.openid)
    tab_insert(params, user_tab.nick_name)
    tab_insert(params, user_tab.gender)
    tab_insert(params, user_tab.country)
    tab_insert(params, user_tab.province)
    tab_insert(params, user_tab.city)
    tab_insert(params, user_tab.avatar_url)
    tab_insert(params, user_tab.union_id)
    tab_insert(params, user_tab.appid)
    tab_insert(params, user_tab.addtime)
    tab_insert(params, user_tab.logintime)

    local ok, errno = db.insert(sql, params)
    if not ok then
        log.err("微信用户信息插入数据库失败")
    end

    return ok
end


function _M.update(user_tab)
    local sql = "UPDATE users SET nickName=%s, gender=%d, country=%s, province=%s, city=%s, " ..
                "avatarUrl=%s, unionId=%s, appId=%s, logintime=%s where openId=%s"

    local params = {}
    tab_insert(params, user_tab.nick_name)
    tab_insert(params, user_tab.gender)
    tab_insert(params, user_tab.country)
    tab_insert(params, user_tab.province)
    tab_insert(params, user_tab.city)
    tab_insert(params, user_tab.avatar_url)
    tab_insert(params, user_tab.union_id)
    tab_insert(params, user_tab.appid)
    tab_insert(params, user_tab.logintime)
    tab_insert(params, user_tab.openid)

    local ok, errno = db.update(sql, params)
    if not ok then
        log.err("微信用户信息更新失败")
    end

    return ok
end


function _M.query(openid)
    local sql = "SELECT * FROM users WHERE openId=%s limit 1"

    local params = {openid}

    return db.select(sql, params)
end


return _M
