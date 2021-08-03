# lua-lib

进一步封装 OPQ 的 lua api，调用更统一，简化开发，去除插件冗余代码, 免受 OPQ wiki 的困扰

<!--ts-->

- [lua-lib](#lua-lib)
  - [安装](#安装)
    - [手动](#手动)
    - [自动](#自动)
  - [使用](#使用)
    - [包装函数](#包装函数)
      - [action](#action)
      - [action 当前可用方法](#action-当前可用方法)
    - [宏(macros)](#宏macros)
    - [日志(log)](#日志log)
    - [网络请求(HTTP)](#网络请求http)
      - [http.request(method, url [, options])](#httprequestmethod-url--options)
      - [Response](#response)
      - [快捷方法](#快捷方法)
    - [其他](#其他)

<!-- Added by: wongxy, at: Fri Jul 30 13:56:38 CST 2021 -->

<!--te-->

## 安装

### 手动

将 `botoy.lua` 下载至插件目录下的 lib 文件夹中，即`Plugins/lib/botoy.lua`

或

```bash
git clone https://github.com/opq-osc/lua-lib.git Plugins/lib
```

### 自动

## 使用

### 包装函数

原来：

```lua
function ReceiveFriendMsg(CurrentQQ, data)
	return 1
end

function ReceiveGroupMsg(CurrentQQ, data)
	return 1
end

function ReceiveEvents(CurrentQQ, data, extData)
	return 1
end
```

现在：

```lua
local botoy = require("Plugins/lib/botoy")

ReceiveGroupMsg = botoy.group(function(CurrentQQ, data, action)
	return 1
end)

ReceiveFriendMsg = botoy.friend(function(CurrentQQ, data, action)
	return 1
end)

ReceiveEvents = botoy.event(function(CurrentQQ, data, extData, action)
	return 1
end)
```

这三个函数都是**可选**使用进行包装的

#### action

action 是主要内容，仅仅是封装了繁杂且没必要的 api 发送代码

用法举例：

```lua
--发送好友文字
action:sendFriendText(123456, 'ok')

--发送群聊网络图片
action:sendGroupUrlPic(654321, 'https://avatars.githubusercontent.com/u/82746709?s=200&v=4')
```

#### action 当前可用方法

1. 参数名前面有\*号的是必传参数
2. 无特殊说明 user 表示好友(用户)QQ，group 表示群号
3. 参数 at 表示需要艾特的人，可以单个 qq 也可以是 qq 列表

| 方法名                                                             | 说明                               |
| ------------------------------------------------------------------ | ---------------------------------- |
| `sendGroupText(*group, *text, at)`                                 | 群文字                             |
| `sendFriendText(*user, *text)`                                     | 好友文字                           |
| `sendPrivateText(*user, *group, *text)`                            | 私聊文字                           |
| `sendFriendTeXiaoText(*user, *text)`                               | 好友特效文字                       |
| `sendGroupTeXiaoText(*group, *text)`                               | 群特效文字                         |
| `sendPhoneText(*text)`                                             | 手机文字                           |
| `replyGroupMsg(*group, *text, *msgSeq, msgTime, user, rawContent)` | 回复群消息                         |
| `replyFriendMsg(*user, *text, *msgSeq, msgTime, rawContent)`       | 回复好友消息                       |
| `sendGroupUrlPic(*group, *url, text, at, flash)`                   | 群链接图片, flash 表示闪照，下同   |
| `sendGroupBase64Pic(*group, *base64, text, at, flash)`             | 群 base64 图片                     |
| `sendGroupMD5Pic(*group, *md5, text, at, flash)`                   | 群 md5 图片                        |
| `sendGroupMutiplePic(*group, *md5s)`                               | 群多图(md5s 可单个 MD5 也可是列表) |
| `sendFriendUrlPic(*user, *url, text, flash)`                       | 好友链接图片                       |
| `sendFriendBase64Pic(*user, *base64, text, flash)`                 | 好友 base64 图片                   |
| `sendFriendMD5Pic(*user, *md5, text, flash)`                       | 好友 md5 图片                      |
| `sendPrivateUrlPic(*user, *group, *url, text)`                     | 私聊链接图片                       |
| `sendPrivateBase64Pic(*user, *group, *base64, text)`               | 私聊 base64                        |
| `sendPrivateMD5Pic(*user, *group, *md5, text)`                     | 私聊 md5 图片                      |

**参数名基本能完整表达出该参数的意思，如果还是不确定，看源码即可**

包装后的函数内容 action 自动初始化，作为函数的新增参数传递

如果需要手动新建 Action:

```
action = botoy.new_action(123456) -- 机器人qq号
```

### 宏(macros)

构建 OPQ 发送宏的辅助函数

```lua
botoy.macros.at(123) -- 艾特单个用户 [ATUSER(123)]
botoy.macros.at({123,456}) -- 艾特多个用户 [ATUSER(123,456)]
botoy.macros.userNick(123) -- 获取用户昵称 [GETUSERNICK(123)]
botoy.macros.showPic(40000) -- 秀图 [秀图(40000)]  参数40000 - 50000，不指定则随机返回
```

### 日志(log)

```lua
local log = botoy.log

-- 普通打印, 任意数量参数
log.info('Hello OPQ')
log.info('Hello', 'OPQ', 123456)

-- 格式化打印(格式参考string.format)
log.infoF('当前时间：%s', os.date('%H:%M'))
```

|               |
| ------------- |
| `log.notice`  |
| `log.noticeF` |
| `log.info`    |
| `log.infoF`   |
| `log.error`   |
| `log.errorF`  |

### 网络请求(HTTP)

```lua
local http = botoy.http
```

#### http.request(method, url [, options])

**参数**

| Name    | Type   | Description                |
| ------- | ------ | -------------------------- |
| method  | String | 请求类型 ,'GET', 'POST'... |
| url     | String | 请求地址                   |
| options | Table  | 可选参数                   |

**Options**

| Name    | Type          | Description                                               |
| ------- | ------------- | --------------------------------------------------------- |
| params  | Table         | URL 的 Query 参数                                         |
| query   | String        | URL 的 Query 字符串                                       |
| cookies | Table         | Additional cookies to send with the request               |
| body    | String        | Request body. (请求数据)                                  |
| headers | Table         | 请求头                                                    |
| timeout | Number/String | Request timeout. Number of seconds or String such as "1h" |

**最终的 Query 字符串是 params 和 query 相连接**

**返回结果**

Response or (nil, error message)

#### Response

**属性**

| Name        | Type   | Description                                                 |
| ----------- | ------ | ----------------------------------------------------------- |
| body        | String | 响应体                                                      |
| text        | String | 等于 body                                                   |
| body_size   | Number | 响应体体积                                                  |
| headers     | Table  | 响应头                                                      |
| cookies     | Table  | cookies                                                     |
| status_code | Number | 响应状态码                                                  |
| url         | String | 最终的请求地址                                              |
| json        | 方法   | 返回解码后的 json 数据 resp:json() 等同于 json.decode(body) |

#### 快捷方法

`http.get`, `http.post`, `http.put`, `http.delete`, `http.head`, `http.patch`

如 `http.get('https://example.com')` 等于 `http.request('GET', 'https://example.com')`

### 其他

```lua
botoy.urlencode('你好') -- %E4%BD%A0%E5%A5%BD
botoy.read_file -- 读取文本文件
botoy.read_json -- 读取JSON文件
```
