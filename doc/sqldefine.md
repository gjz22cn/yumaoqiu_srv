## 1. 数据库定义
#### 社团 (corporation)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|id    |int   | |primary key<br>not null auto_increment |

#### 计分卡 (score_card)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|id    |int   ||primary key<br>not null auto_increment |
|name  |varchar(32)|名称|not null|
|type1|ENUM('ranking','full-loop','combat-loop'|类型1：排名、循环、AB队循环||
|type2|ENUM('single','doubles','team',<br>'m-s','f-s',<br>'m-d','f-d','mix-d')|类型2：<br>单打、双打、团体、<br>男单、女单、<br>男双、女双、混双||
|corp_id    |int   | 社团ID|foreign key<br>default: 1, 表示不属于任何社团|


#### 计分条目表 (score_ori)
|字段   |类型  |说明   |备注   |
|:-----|:-----|:------|:------|
|id    |int   | |primary key<br>not null auto_increment|
|card_id    |int   | 积分卡id|foreign key<br>default: 1|
|date  |time|比赛时间||
|state_l|ENUM('0','1','2')|左边状态|0-确认1,1-确认2,2-已确认|
|state_r|ENUM('0','1','2')|右边状态|0-确认1,1-确认2,2-已确认|
|namel_l|varchar(32)|左边选手1名称||
|namel_2|varchar(32)|左边选手2名称||
|namer_l|varchar(32)|右边选手1名称||
|namer_2|varchar(32)|右边选手2名称||
