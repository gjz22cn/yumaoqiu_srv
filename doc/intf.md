## 1 RESTful API List
|URL|METHOD|功能|参数|返回值|
|:----|:----:|:----|:----|:----|
|||||
|/corporation|POST|创建社团|||
|/corporation/[id]|GET|获取社团信息||
|/corporation/[id]|PUT|修改社团信息||
|/corporation/[id]|DELETE|删除社团||
|/corporation/join|POST|加入社团||
|/corporation/leave|POST|离开社团||
|||||
|/activity|POST|创建社团活动|||
|/activity/[id]|GET|获取活动信息||
|/activity/[id]|PUT|修改活动信息||
|/activity/[id]|DELETE|删除活动||
|/activity/join|POST|参加活动|{people: 1}|
|||||
|/score_card|POST|创建计分卡|||
|/score_card/[id]|GET|获取计分卡信息||
|/score_card/[id]|PUT|修改计分卡信息||
|/score_card/[id]|DELETE|删除计分卡||
|||||
|/score_item|POST|创建计分项|{card_id: 1}||
|/score_item/[id]|GET|获取计分项信息||
|/score_item/[id]|PUT|修改计分项信息||
|/score_item/[id]|DELETE|删除计分项||
|/score_item/[id]/confirml_1|POST|左边确认1|{user_id: 1}||
|/score_item/[id]/confirml_2|POST|左边确认2|{user_id: 1}||
|/score_item/[id]/confirmr_1|POST|右边确认1|{user_id: 1}||
|/score_item/[id]/confirmr_2|POST|右边确认2|{user_id: 1}||

