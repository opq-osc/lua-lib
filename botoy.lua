------------------------------------------------------------------------
------------------------------ 一劳永逸 --------------------------------
------------------------------------------------------------------------

--TODO: document comments
------------- settings ------------
--TODO: read from CoreConf.conf
local HOST = '127.0.0.1'
local PORT = 8888
-----------------------------------

local unpack = unpack or table.unpack
local api = require 'coreApi'
local _log = require 'log'

-- TODO: support api using http
-- local http = require("http")

local Action = {}

local FRIEND = 1
local GROUP = 2
local PRIVATE = 3

function Action:new(qq, host, port)
  self.__index = self
  return setmetatable({
    qq = qq,
    host = host or HOST,
    port = port or PORT,
  }, self)
end

----------------------------------------
-------------- macros ----------------
----------------------------------------

local macros = {
  at = function(qq)
    if not qq then
      return ''
    end
    if type(qq) == 'number' then
      qq = { qq }
    end
    return string.format('[ATUSER(%s)]', table.concat(qq, ','))
  end,
  userNick = function(user)
    return string.format('[GETUSERNICK(%d)]', user)
  end,
}

----------------------------------------
-------------- log ----------------
----------------------------------------

local log = {}

local function gen_logger(level, format)
  return function(...)
    local items = {}
    for _, item in ipairs { ... } do
      table.insert(items, tostring(item))
    end

    local msg
    if format then
      msg = string.format(table.remove(items, 1), unpack(items))
    else
      msg = table.concat(items, ' ')
    end

    _log[level]('%s', msg)
  end
end

log.notice = gen_logger 'notice'
log.noticeF = gen_logger('notice', true)
log.info = gen_logger 'info'
log.infoF = gen_logger('info', true)
log.error = gen_logger 'error'
log.errorF = gen_logger('error', true)

----------------------------------------
-------------- api ---------------------
----------------------------------------

----------- common text ----------------

function Action:_sendText(user, group, text, at, t)
  local payload = { SendToType = t, SendMsgType = 'TextMsg', Content = text }
  if t == FRIEND then
    payload.ToUserUid = user
  elseif t == GROUP then
    payload.ToUserUid = group
    if at then
      payload.Content = macros.at(at) .. '\n' .. payload.Content
    end
  else
    payload.ToUserUid = user
    payload.GroupID = group
  end
  return api.Api_SendMsgV2(self.qq, payload)
end

---发送群文字
---@param group number: *群号
---@param text string: *内容
---@param at number | table: 艾特用户(列表)
function Action:sendGroupText(group, text, at)
  return self:_sendText(nil, group, text, at, GROUP)
end

---发送好友文字
---@param user number: *好友QQ
---@param text string: *内容
function Action:sendFriendText(user, text)
  return self:_sendText(user, nil, text, nil, FRIEND)
end

---发送私聊文字
---@param user number: *用户QQ
---@param group number: *发起私聊群号
---@param text string: *内容
function Action:sendPrivateText(user, group, text)
  return self:_sendText(user, group, text, nil, PRIVATE)
end

----------- special text ----------------

---发送好友特效文字
---@param user number: *好友QQ
---@param text string: *内容
function Action:sendFriendTeXiaoText(user, text)
  return api.Api_SendMsgV2(
    self.qq,
    { ToUserUid = user, SendToType = FRIEND, SendMsgType = 'TeXiaoTextMsg', Content = text }
  )
end

---发送群聊特效文字
---@param group number: *群号
---@param text string: *内容
function Action:sendGroupTeXiaoText(group, text)
  return api.Api_SendMsgV2(
    self.qq,
    { ToUserUid = group, SendToType = GROUP, SendMsgType = 'TeXiaoTextMsg', Content = text }
  )
end

---给机器人手机发送文字
---@param text string: *内容
function Action:sendPhoneText(text)
  return api.Api_SendMsgV2(self.qq, { SendToType = 2, SendMsgType = 'PhoneMsg', Content = text })
end

----------- rich message ----------------

---回复群消息
---@param group number: *群号
---@param text string: *回复内容
---@param msgSeq number: *回复的消息序列号
---@param msgTime number: 回复的消息时间
---@param user number: 回复的消息的发送者
---@param rawContent string: 回复的消息的原内容
function Action:replyGroupMsg(group, text, msgSeq, msgTime, user, rawContent)
  local payload = {
    toUser = group,
    sendToType = GROUP,
    sendMsgType = 'ReplayMsg',
    content = text,
    replayInfo = {
      MsgSeq = msgSeq,
      MsgTime = msgTime or os.time(),
      UserID = user or 0,
      RawContent = rawContent or '',
    },
  }
  return api.Api_SendMsg(self.qq, payload)
end

---回复好友消息
---@param user number: *好友QQ
---@param text string: *回复内容
---@param msgSeq number: *回复的消息序列号
---@param msgTime number: 回复的消息时间
---@param rawContent string: 回复的消息的原内容
function Action:replyFriendMsg(user, text, msgSeq, msgTime, rawContent)
  local payload = {
    toUser = user,
    sendToType = FRIEND,
    sendMsgType = 'ReplayMsg',
    content = text,
    replayInfo = {
      MsgSeq = msgSeq,
      MsgTime = msgTime or os.time(),
      UserID = user,
      RawContent = rawContent or '',
    },
  }
  return api.Api_SendMsg(self.qq, payload)
end

----------- pic ----------------

function Action:_sendPic(user, group, text, url, base64, md5, md5s, flash, at, t)
  text = text or ''
  if t == GROUP then
    -- 多图只有群聊可以
    if at then
      text = macros.at(at) .. '\n' .. text
    end
    if md5s then
      return api.Api_SendMsgV2(self.qq, {
        ToUserUid = group,
        SendToType = GROUP,
        SendMsgType = 'PicMsg',
        PicMd5s = type(md5s) == 'table' and md5s or { md5s },
      })
    end
    return api.Api_SendMsg(self.qq, {
      toUser = group,
      sendToType = GROUP,
      sendMsgType = 'PicMsg',
      content = text or '',
      picUrl = url or '',
      picBase64Buf = base64 or '',
      fileMd5 = md5 or '',
      flashPic = flash or false,
    })
  elseif t == FRIEND then
    return api.Api_SendMsg(self.qq, {
      toUser = user,
      sendToType = FRIEND,
      sendMsgType = 'PicMsg',
      content = text or '',
      picUrl = url or '',
      picBase64Buf = base64 or '',
      fileMd5 = md5 or '',
      flashPic = flash or false,
    })
  else
    return api.Api_SendMsg(self.qq, {
      toUser = user,
      groupid = group,
      sendToType = PRIVATE,
      sendMsgType = 'PicMsg',
      content = text or '',
      picUrl = url or '',
      picBase64Buf = base64 or '',
      fileMd5 = md5 or '',
      flashPic = flash or false,
    })
  end
end

-- group

---发送群链接图片
---@param group number: *群号
---@param url string: *图片链接
---@param text string: 文字内容
---@param at number | table: 艾特用户(列表)
---@param flash boolean: 是否闪照
function Action:sendGroupUrlPic(group, url, text, at, flash)
  return self:_sendPic(nil, group, text, url, nil, nil, nil, flash, at, GROUP)
end

---发送群base64图片
---@param group number: *群号
---@param base64 string: *图片base64
---@param text string: 文字内容
---@param at number | table: 艾特用户(列表)
---@param flash boolean: 是否闪照
function Action:sendGroupBase64Pic(group, base64, text, at, flash)
  return self:_sendPic(nil, group, text, nil, base64, nil, nil, flash, at, GROUP)
end

---发送群base64图片
---@param group number: *群号
---@param md5 string: *图片md5
---@param text string: 文字内容
---@param at number | table: 艾特用户(列表)
---@param flash boolean: 是否闪照
function Action:sendGroupMD5Pic(group, md5, text, at, flash)
  return self:_sendPic(nil, group, text, nil, nil, md5, flash, at, GROUP)
end

---发送群多图
---@param group number: *群号
---@param md5s string | table: *图片md5或md5列表
function Action:sendGroupMutiplePic(group, md5s)
  return self:_sendPic(nil, group, nil, nil, nil, nil, md5s, nil, nil, GROUP)
end

-- friend

---发送好友链接图片
---@param user number: *好友QQ
---@param url string: *图片链接
---@param text string: 文字内容
---@param flash boolean: 是否闪照
function Action:sendFriendUrlPic(user, url, text, flash)
  return self:_sendPic(user, nil, text, url, nil, nil, nil, flash, nil, FRIEND)
end

---发送好友base64图片
---@param user number: *好友QQ
---@param base64 string: *图片base64
---@param text string: 文字内容
---@param flash boolean: 是否闪照
function Action:sendFriendBase64Pic(user, base64, text, flash)
  return self:_sendPic(user, nil, text, nil, base64, nil, nil, flash, nil, FRIEND)
end

---发送好友md5图片
---@param user number: *好友QQ
---@param md5 string: *图片md5
---@param text string: 文字内容
---@param flash boolean: 是否闪照
function Action:sendFriendMD5Pic(user, md5, text, flash)
  return self:_sendPic(user, nil, text, nil, nil, md5, nil, flash, nil, FRIEND)
end

-- private

---发送私聊链接图片
---@param user number: *用户QQ
---@param group number: *发送私聊群号
---@param url string: *图片链接
---@param text string: 文字内容
function Action:sendPrivateUrlPic(user, group, url, text)
  return self:_sendPic(user, group, text, url, nil, nil, nil, nil, nil, PRIVATE)
end

---发送私聊base64图片
---@param user number: *用户QQ
---@param group number: *发送私聊群号
---@param base64 string: *图片base64
---@param text string: 文字内容
function Action:sendPrivateBase64Pic(user, group, base64, text)
  return self:_sendPic(user, group, text, nil, base64, nil, nil, nil, nil, PRIVATE)
end

---发送私聊md5图片
---@param user number: *用户QQ
---@param group number: *发送私聊群号
---@param md5 string: *图片md5
---@param text string: 文字内容
function Action:sendPrivateMD5Pic(user, group, md5, text)
  return self:_sendPic(user, group, text, nil, nil, md5, nil, nil, nil, PRIVATE)
end

----------- module ------------------

---新建Action
---@param qq number: *机器人QQ号
---@param host string: 服务地址
---@param port number: 服务端口
---@return table
local function new_action(qq, host, port)
  return Action:new(qq, host, port)
end

return {
  group = function(callback)
    return function(qq, data)
      return callback(qq, data, Action:new(qq))
    end
  end,
  friend = function(callback)
    return function(qq, data)
      return callback(qq, data, Action:new(qq))
    end
  end,
  event = function(callback)
    return function(qq, data, extData)
      return callback(qq, data, extData, Action:new(qq))
    end
  end,
  new_action = new_action,
  macros = macros,
  log = log,
}
