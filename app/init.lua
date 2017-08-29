local routers = require "routers"
local traceback = debug.traceback

local log = require "utils.log"
local m_game = require "model.game"
local localtime = ngx.localtime


local delay = 3600

local function update_progress(premature)
    m_game.update_progress(localtime())

    local ok, err = ngx.timer.at(delay, update_progress)
    if not ok then
        log.err("failed to create timer: ", err)
        return
    end
end

local _M = {}

function _M.init()
    local status, err_msg = xpcall(function() routers.set_routers() end,
    function(msg) local ret_msg = traceback() return ret_msg end)
    if not status then
        log.crit('--init worker error--')
        log.err(err_msg)
        return
    end

    if ngx.worker.id() == 0 then
        local ok, err = ngx.timer.at(0, update_progress)
        if not ok then
            log.err("failed to create timer: ", err)
            return
        end
    end

end

return _M
