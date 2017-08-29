local parser = require "resty.multipart.parser"
local uuid = require "resty.uuid"
local ngx_re = require "ngx.re"
local gsub = ngx.re.gsub
local log = require "utils.log"

local allow_exts={
    ['jpg'] = true,
    ['jpeg'] = true,
    ['png'] = true,
    ['bmp'] = true
}

local _M = {}

function _M.parser(body, pic_dir)
    local result = {}

    local p, err = parser.new(body, ngx.var.http_content_type)
    if not p then
        log.err("failed to create parser: ", err)
        return nil
    end

    while true do
        local part_body, name, mime, filename = p:parse_part()
        if not part_body then
            break
        end

        if not filename then
            result[name] = part_body
        else
            local pic_list, err = ngx_re.split(filename, "\\.")
            local postfix = pic_list[#pic_list]
            if not allow_exts[string.lower(postfix)] then
                log.err('文件类型不允许:', postfix)
                return nil
            end

            local uuid_str = uuid.generate_time()
            local new_uuid_str = gsub(uuid_str, "-", "", "jo")
            filename = new_uuid_str .. "." .. string.lower(postfix)
            if result.filenames then
                table.insert(result.filenames, filename)
            else
                result.filenames = {}
                table.insert(result.filenames, filename)
            end

            if pic_dir then
                filename = pic_dir .. filename
                file = io.open(filename, "w")
                if not file then
                    log.err('open file failed: ', filename)
                    return nil
                end
                file:write(part_body)
                file:close()
            end
        end
    end

    return result
end

return _M
