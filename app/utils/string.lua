local gsub = ngx.re.gsub
local ngx_re = require "ngx.re"
local tab_insert = table.insert
local tab_concat = table.concat
local str_format = string.format
local str_sub = string.sub
local str_gsub = string.gsub
local u_table = require "utils.table"
local ngx_quote_sql_str = ngx.quote_sql_str
local log = require "utils.log"

local _M = {}

function _M.time_format(time_stamp)
    local res_tab = {}
    tab_insert(res_tab, str_sub(time_stamp, 1, 4))
    tab_insert(res_tab, "-")
    tab_insert(res_tab, str_sub(time_stamp, 5, 6))
    tab_insert(res_tab, "-")
    tab_insert(res_tab, str_sub(time_stamp, 7, 8))
    tab_insert(res_tab, " ")
    tab_insert(res_tab, str_sub(time_stamp, 9, 10))
    tab_insert(res_tab, ":")
    tab_insert(res_tab, str_sub(time_stamp, 11, 12))
    tab_insert(res_tab, ":")
    tab_insert(res_tab, str_sub(time_stamp, 13, 14))
    return tab_concat(res_tab, "")
end

-- 字符串去掉左右空格
function _M.trim (s)
    return str_gsub(s, "^%s*(.-)%s*$", "%1")
end

-- 手机号码格式校验
function _M.is_phone(phone)
    local m, err = ngx.re.match(phone, "^(13|14|15|17|18)\\d{9}$", "jo")
    if not m then
        return false, err
    end
    return true
end

-- ip字符串转INT
function _M.ip_str2int(ip)
    local res, err = ngx_re.split(ip, "\\.")
    if not res then
        return nil, err
    end

    local sum = 0
    for i, val in ipairs(res) do
        sum = sum + tonumber(val) * math.pow(255, 4-i)
    end

    return sum
end

-- list, 拼接成字符串 用于执行sql的in
function _M.list2str(tab, key)
    local id_list = {}
    for _, tab_info in ipairs(tab) do
        tab_insert(id_list, tab_info[key])
    end
    return "('" .. tab_concat(id_list, "','") .. "')"
end


-- sql 格式化
function _M.parse_sql(sql, params)
    if not params or not u_table.is_array(params) or #params == 0 then
        return sql
    end

    if not sql then return nil end

    local new_params = {}
    for _, v in ipairs(params) do
        if type(v) == 'string' then
            tab_insert(new_params, ngx_quote_sql_str(v))
        else
            tab_insert(new_params, v)
        end
    end

    log.debug(sql)
    log.debug(unpack(new_params))

    sql = str_format(sql, unpack(new_params))
    return sql
end

return _M
