-- 常量

local _M = {}

_M.URL = {
    WX_CODE2SESSION = 'https://api.weixin.qq.com/sns/jscode2session'
}

_M.GAME_TYPE = {
    '男单', '女单', '男双', '女双', '混双', '团体', '社团活动'
}

_M.TEAM_TYPE = {
    '男单', '女单', '男双', '女双', '混双'
}

_M.GAME_PROGRESS = {
    '报名中', '进行中', '已结束'
}

return _M
