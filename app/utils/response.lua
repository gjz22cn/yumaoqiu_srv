local ngx_print = ngx.print

-- 异常错误码定义
local error_msg = {
    ['000000'] = '成功',
    ['400000'] = '错误请求',
    ['400001'] = '请求无效, 缺少必传参数',
    ['401000'] = '未授权',
    ['401001'] = '用户不存在或密码错误',
    ['403000'] = '禁止访问',
    ['404000'] = '找不到',
    ['500000'] = '内部服务器错误',
    ['600001'] = '请求微信接口异常',
    ['600002'] = '登录失败',
    ['600003'] = '签名验证未通过',
    ['600004'] = 'AES解密APPID验证失败',
    ['600101'] = '创建比赛失败',
    ['600102'] = '比赛查询失败',
    ['600103'] = '比赛更新失败',
    ['600104'] = '比赛删除失败',
    ['600105'] = '社团活动报名名单查询失败',
    ['600106'] = '报名人数查询失败',
    ['600201'] = '比赛报名失败',
    ['600202'] = '取消报名失败',
    ['600301'] = '赛程添加失败',
    ['600302'] = '赛程更新失败',
    ['600303'] = '赛程删除失败',
    ['700001'] = '数据库连接异常',
    ['700002'] = '数据库操作异常',
}

local _M = {}

function _M.send(resp)
    ngx.header['Access-Control-Allow-Origin'] = '*'
    ngx_print(resp)
end

function _M.get_errmsg(key)
    return error_msg[key] or '未知错误'
end

return _M