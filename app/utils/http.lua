local http = require "resty.http"
local log = require "utils.log"
local u_table = require "utils.table"

local _M = {}


function _M.post(url, req_body_tab)
    local req_body_str = u_table.table2str(req_body_tab)
    log.info("请求url: ", url, " 请求body: ", req_body_str)

    local httpc = http.new()
    local res, err = httpc:request_uri(url, {
        method = "POST",
        query = req_body_str,
        headers = {
            ["Content-Type"] = "application/x-www-form-urlencoded",
        }
    })

    if not res or res.status ~= 200 then
        log.err("请求失败: ", err)
        return nil
    end

    log.info("返回body: ", res.body)

    return res.body

    -- close http
    --[[
    local ok, err = httpc:close()
    if not ok then
        log.err("failed to close http connection: ", err)
    end
    ]]

end


return _M
