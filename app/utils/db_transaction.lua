local mysql = require "resty.mysql"
local config = require "config"
local log = require "utils.log"
local cjson = require "cjson"
local u_string = require "utils.string"

local _M = {}

local mt = {__index = _M}

function _M.new(self)
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
        return nil
    end

    return setmetatable({ db = db }, mt)
end


-- 开启事务
function _M.transaction_start(self)
    local db = self.db

    local res, err, errno, sqlstate = db:query("START TRANSACTION")
    if not res then
        log.err("START TRANSACTION failed: ", err, ": ", errno, ": ", sqlstate)
        return nil
    end

    return true
end


-- 提交事务
function _M.transaction_commit(self)
    local db = self.db

    local res, err, errno, sqlstate = db:query("COMMIT")
    if not res then
        log.err("COMMIT failed: ", err, ": ", errno, ": ", sqlstate)
        return nil
    end

    -- 连接池
    local pool = config.get('mysql_pool')
    local ok, err = db:set_keepalive(pool.timeout, pool.size)
    if not ok then
        log.err("failed to set keepalive: " .. err)
    end

    return true
end


-- 回滚事务
function _M.transaction_rollback(self)
    local db = self.db

    local res, err, errno, sqlstate = db:query("ROLLBACK")
    if not res then
        log.err("ROLLBACK failed: ", err, ": ", errno, ": ", sqlstate)
        return nil
    end

    -- 连接池
    local pool = config.get('mysql_pool')
    local ok, err = db:set_keepalive(pool.timeout, pool.size)
    if not ok then
        log.err("failed to set keepalive: " .. err)
    end

    return true
end


-- 执行sql
function _M.execute(self, sql, params)
    local sql = u_string.parse_sql(sql, params)
    log.debug(sql)
    if not sql then
        log.err("sql format error: ", sql, ": ", cjson.encode(params))
        return nil
    end

    local db = self.db

    local res, err, errno, sqlstate = db:query(sql)
    if not res then
        log.err("sql execute failed: ", err, ": ", errno, ": ", sqlstate)
        return nil, errno
    end

    return res
end


function _M.select(self, sql, params)
    return self:execute(sql, params)
end

function _M.insert(self, sql, params)
    local res, errno = self:execute(sql, params)
    if res and res.affected_rows > 0 then
        return true
    else
        return false, errno
    end
end

function _M.update(self, sql, params)
    local res, errno = self:execute(sql, params)
    if res and res.affected_rows > 0 then
        return true
    else
        return false, errno
    end
end

function _M.delete(self, sql, params)
    local res, errno = self:execute(sql, params)
    if res and res.affected_rows > 0 then
        return true
    else
        return false, errno
    end
end

return _M
