local slaxml = require "resty.slaxdom"
local tab_insert = table.insert
local tab_concat = table.concat
local tab_sort = table.sort
local str_format = string.format

local _M = {}

-- 判断table是否为空
function _M.is_empty(t)
    if t == nil or next(t) == nil then
        return true
    else
        return false
    end
end

function _M.is_array(t)
    if type(t) ~= "table" then return false end
    local i = 0
    for _ in pairs(t) do
        i = i + 1
        if t[i] == nil then return false end
    end
    return true
end

-- table转字符串
function _M.table2str(tab)
    local res_tab = {}

    for key, val in pairs(tab) do
        tab_insert(res_tab, str_format('%s=%s', key, val))
    end

    return tab_concat(res_tab, "&")
end

-- table取部分转成字符串
function _M.table2str_by_keys(tab, keys)
    local res_tab = {}
    for _, key in pairs(keys) do
        tab_insert(res_tab, str_format('%s=%s', key, tab[key] or ''))
    end
    return tab_concat(res_tab, '&')
end

-- table中value值urlencode
function _M.table2str_urlencode(tab)
    local res_tab = {}
    for k, v in pairs(tab) do
        tab_insert(res_tab, str_format('%s=%s', k, ngx.escape_uri(v)))
    end
    return tab_concat(res_tab, "&")
end

-- table转字符串, 按key升序排
function _M.table2str_order(tab)
    local res_tab = {}

    local key_tab = {}
    -- 取出所有的键
    for key, _ in pairs(tab) do
        if key ~= 'sign' then
            tab_insert(key_tab, key)
        end
    end
    -- 对所有键进行排序
    tab_sort(key_tab)
    for _, key in pairs(key_tab) do
        -- 为空值不参与签名
        if tab[key] and tab[key] ~= "" then
            tab_insert(res_tab, str_format('%s=%s', key, tab[key]))
        end
    end

    return tab_concat(res_tab, "&")
end


-- table转xml格式
function _M.table2xml(tab)
    local res_tab = {}
    tab_insert(res_tab, "<xml>")

    for key, val in pairs(tab) do
        tab_insert(res_tab, str_format('<%s>%s</%s>', key, val, key))
    end

    tab_insert(res_tab, "</xml>")

    return tab_concat(res_tab, "")
end

-- xml转table
function _M.xml2table(xml)
    local res_tab = {}
    local doc = slaxml:dom(xml)
    local root = doc.root
    for i = 1, #root.el, 1 do
        res_tab[root.el[i].name] = root.el[i].kids[1].value
    end

    return res_tab
end

return _M
