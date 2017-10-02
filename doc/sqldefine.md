### 用户 (users)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|id    |int   | |primary key<br>not null, auto_increment |
|openId |int |微信用户ID |unique|
|phone  |varchar(11) |手机号 ||
|password  |varchar(128) | ||
|nickName  |varchar(128) |微信昵称||
|gender  |int(11) | ||
|country  |varchar(32) | ||
|province  |varchar(32) | ||
|city  |varchar(32) | ||
|avatarUrl  |varchar(256) | ||
|unionId  |varchar(32) | ||
|appId  |varchar(32) | ||
|addtime  |char(19) | ||
|logintime  |char(19) | ||

### 社团 (corporation)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|id    |int   | |primary key<br>not null auto_increment |
|name  |varchar(32)|名称|not null|
|act_add1  |varchar(128)|活动地址1||
|act_add2  |varchar(128)|活动地址2||
|act_add3  |varchar(128)|活动地址3||
|user_id    |int   |管理员ID|foreign key|
|mem_num    |int   |成员数目|default: 1|

### 社团成员(corp_mem)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|corp_id    |int   | 社团ID|foreign key|
|user_id    |int   | 用户ID|foreign key|

### 社团活动(activity)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|id    |int   | |primary key<br>not null auto_increment|
|date  |date|活动日期|年-月-日|
|start |time|开始时间|时：分|
|end |time|结束时间|时：分|
|addr |varchar(128)|活动地址||
|comment|varchar(256)|备注||

### 活动成员(act_mem)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|act_id    |int   | 活动ID|foreign key|
|user_id    |int   | 用户ID|foreign key|
|people    |int   | 报名人数|default：1|

### 计分卡 (score_card)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|id    |int   ||primary key<br>not null auto_increment |
|name  |varchar(32)|名称|not null|
|type1|ENUM('ranking','full-loop','combat-loop')|类型1：排名、循环、AB队循环||
|type2|ENUM('single','doubles','team',<br>'m-s','f-s',<br>'m-d','f-d','mix-d')|类型2：<br>单打、双打、团体、<br>男单、女单、<br>男双、女双、混双||
|user_id    |int   | 用户ID|foreign key, not null|
|corp_id    |int   | 社团ID|foreign key<br>default: 1, 表示不属于任何社团|

### 计分卡成员(card_mem)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|card_id    |int   | 记分卡ID|foreign key|
|user_id    |int   | 用户ID|foreign key|

### 计分条目表 (score_item)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|id    |int   | |primary key<br>not null auto_increment|
|card_id    |int   | 积分卡id|foreign key<br>default: 1|
|date  |date|比赛时间||
|state|int|计分条目状态|0-未完成,1-完成,default:0|
|state_l|ENUM('0','1','2')|左边状态|0-确认1,1-确认2,2-已确认|
|state_r|ENUM('0','1','2')|右边状态|0-确认1,1-确认2,2-已确认|
|namel_l|varchar(32)|左边选手1名称||
|namel_2|varchar(32)|左边选手2名称||
|namer_l|varchar(32)|右边选手1名称||
|namer_2|varchar(32)|右边选手2名称||
