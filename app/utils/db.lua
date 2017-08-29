local mysql = require "resty.mysql"
local config = require "config"
local log = require "utils.log"
local cjson = require "cjson"
local u_string = require "utils.string"

local _M = {}

-- 抽象数据库操作
local function execute(sql)
    local db, err = mysql:new()
    if not db then
        log.err("failed to instantiate mysql: ", err)
        return nil
    end

    -- 连接超时时间
    db:set_timeout(config.get('mysql_conn_timeout'))

    -- 连接数据库
    local ok, err, errno, sqlstate = db:connect(config.get('mysql_conn'))
    if not ok then
        log.err("failed to connect: ", err, ": ", errno, ": ", sqlstate)
        return nil, errno
    end

    -- execute sql
    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        log.err("query failed: [", sql, "]", err, ": ", errno, ": ", sqlstate)
        return nil, errno
    end

    -- 连接池
    local pool = config.get('mysql_pool')
    local ok, err = db:set_keepalive(pool.timeout, pool.size)
    if not ok then
        log.err("failed to set keepalive: " .. err)
        -- return nil
    end

    return res
end

local function query(sql, params)
    local sql = u_string.parse_sql(sql, params)
    if not sql then
        log.err("sql format error: ", sql, ": ", cjson.encode(params))
        return nil
    end

    log.debug(sql)

    return execute(sql)
end

function _M.select(sql, params)
    return query(sql, params)
end

function _M.insert(sql, params)
    local res, errno = query(sql, params)
    if res and res.affected_rows > 0 then
        return true
    else
        return false, errno
    end
end

function _M.update(sql, params)
    local res, errno = query(sql, params)
    if res and res.affected_rows > 0 then
        return true
    else
        return false, errno
    end
end

function _M.delete(sql, params)
    local res, errno = query(sql, params)
    if res and res.affected_rows > 0 then
        return true
    else
        return false, errno
    end
end

return _M
