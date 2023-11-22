# 目录

- [目录](#目录)
- [写在前面](#写在前面)
- [简介](#简介)
  - [对用户](#对用户)
  - [对开发者](#对开发者)
  - [我们的宗旨](#我们的宗旨)
- [基础功能一览](#基础功能一览)
  - [登录（非对称加密验证）](#登录非对称加密验证)
  - [外观界面](#外观界面)
    - [暗色模式](#暗色模式)
    - [修改主题色](#修改主题色)
  - [好友系统](#好友系统)
    - [好友列表](#好友列表)
    - [添加好友](#添加好友)
    - [删除好友](#删除好友)
  - [IM系统](#im系统)
    - [在线聊天](#在线聊天)
      - [发送表情](#发送表情)
      - [发送图片、视频](#发送图片视频)
      - [回复](#回复)
      - [已读](#已读)
      - [撤回](#撤回)
      - [删除](#删除)
      - [屏蔽](#屏蔽)
    - [会话置顶与删除](#会话置顶与删除)
    - [上线时同步消息](#上线时同步消息)
  - [小程序系统](#小程序系统)
    - [小程序仓库](#小程序仓库)
    - [小程序内容推荐流（实时热榜）](#小程序内容推荐流实时热榜)
    - [小程序向用户发送消息](#小程序向用户发送消息)
  - [版本更新](#版本更新)
    - [开发者笔记](#开发者笔记)
    - [获取最新版本](#获取最新版本)
- [小程序一览](#小程序一览)
  - [墙贴](#墙贴)
    - [有想法？贴一贴！](#有想法贴一贴)
    - [momo是谁？momo是我。](#momo是谁momo是我)
    - [时间线全览，发生什么，一看就懂。](#时间线全览发生什么一看就懂)
    - [实时热点千万别错过！](#实时热点千万别错过)
    - [多角度搜索，无处遁逃。](#多角度搜索无处遁逃)
  - [聊聊屋](#聊聊屋)
    - [今天想进哪个频道？](#今天想进哪个频道)
    - [微服私访，今天的身份是？](#微服私访今天的身份是)
    - [天啊，这个人真的好机车欸！](#天啊这个人真的好机车欸)
    - [双方进行了友好的私聊，充分交流了意见。](#双方进行了友好的私聊充分交流了意见)
  - [搭搭](#搭搭)
    - [正在前往，搭搭广场。](#正在前往搭搭广场)
    - [正在发布，搭搭请求。](#正在发布搭搭请求)
    - [正在设计，搭搭名片。](#正在设计搭搭名片)
  - [中古](#中古)
    - [在淘好货，一网打尽。](#在淘好货一网打尽)
    - [诚心求购，快速发布。](#诚心求购快速发布)
    - [频道搜索，火眼金睛。](#频道搜索火眼金睛)
    - [成交记录，帮你统计。](#成交记录帮你统计)
- [项目架构](#项目架构)

# 写在前面

本项目移动端采用Flutter（Dart）构建，后端基建以及主体服务采用.NET（C#）构建，数据存储涉及SQLite（移动端本地存储）、SqlServer、MongoDB与Redis，同时使用了各类中间件（网关、服务注册与发现、日志系统、消息队列、对象存储等），服务及中间件通过Docker进行容器化部署。  

本仓库为MetaUni移动端代码仓库，同时也是MetaUni项目的主体仓库。若要查看MetaUni项目下的其它代码仓库，可参阅该仓库目录：  
- [MetaUni-MetaUniGateWay 主体网关](https://github.com/baichuanjiu/MetaUni-MetaUniGateway)
- [MetaUni-MetaUniServer 主体服务器](https://github.com/baichuanjiu/MetaUni-MetaUniServer)
- [MetaUni-UnifiedAssistantRpcServer 提供接口供小程序调用的RPC服务器](https://github.com/baichuanjiu/MetaUni-UnifiedAssistantRpcServer)
- [MetaUni-WallSticker-WallStickerGateway 小程序“墙贴”网关](https://github.com/baichuanjiu/MetaUni-WallSticker-WallStickerGateway)
- [MetaUni-WallSticker-WallStickerServer 小程序“墙贴”服务器](https://github.com/baichuanjiu/MetaUni-WallSticker-WallStickerServer)
- [MetaUni-ChatRoom-ChatRoomServer 小程序“聊聊屋”服务器](https://github.com/baichuanjiu/MetaUni-ChatRoom-ChatRoomServer)
- [MetaUni-SeekPartner-SeekPartnerGateway 小程序“搭搭”网关](https://github.com/baichuanjiu/MetaUni-SeekPartner-SeekPartnerGateway)
- [MetaUni-SeekPartner-SeekPartnerServer 小程序“搭搭”服务器](https://github.com/baichuanjiu/MetaUni-SeekPartner-SeekPartnerServer)
- [MetaUni-FleaMarket-FleaMarketGateway 小程序“中古”网关](https://github.com/baichuanjiu/MetaUni-FleaMarket-FleaMarketGateway)
- [MetaUni-FleaMarket-FleaMarketServer 小程序“中古”服务器](https://github.com/baichuanjiu/MetaUni-FleaMarket-FleaMarketServer)

# 简介

MetaUni，以IM（即时通讯）为基础、集成了多种功能的软件平台，致力于为用户与开发者提供便捷的一站式服务。

## 对用户

- 一个账号，平台通用
- 校内运营，不含广告
- 注重体验，用户授权
- 项目开源，安全可控
  
V1.0.0版本集成了基础的IM功能、好友系统、小程序系统、小程序内容推荐流、版本更新等。  
  
现在可用的小程序有：
- 墙贴（类Twitter）
- 聊聊屋（在线聊天室）
- 搭搭（寻找搭子）
- 中古（二手交易市场）  
    
后续更新计划：课表（可能）、论坛（可能）等。

## 对开发者

- 语言友好，小程序前端可使用Flutter开发（作为本地应用汇入主仓库），也可使用Web语言（或框架）开发（作为网页应用通过WebView打开），后端更是不限制开发语言与开发思路。
- 基建完善，前端包装好了许多通用组件与方法，后端必要的接口（如获取用户信息、向用户发送消息等）可通过rpc进行访问，开发者无需关注过多的底层细节，开发时仅需专注于自身页面与功能逻辑。
- 曝光稳定，开发者填写必要信息，注册好小程序即可通过平台被用户访问，此外还通过rpc向开发者开放推流接口，可将小程序内容推送至平台“推荐”页。
  
后续更新计划：更方便使用与配置的开发者后台。

## 我们的宗旨

- 面向校内
- 开源共建
- 多元包容

# 基础功能一览

## 登录（非对称加密验证）
![登录.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E7%99%BB%E5%BD%95.gif?raw=true)
## 外观界面
### 暗色模式
![暗色模式.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E6%9A%97%E8%89%B2%E6%A8%A1%E5%BC%8F.gif?raw=true)
### 修改主题色
![修改主题色.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E4%BF%AE%E6%94%B9%E4%B8%BB%E9%A2%98%E8%89%B2.gif?raw=true)
## 好友系统
### 好友列表
![好友列表.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%A5%BD%E5%8F%8B%E5%88%97%E8%A1%A8.gif?raw=true)
### 添加好友
![添加好友.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E6%B7%BB%E5%8A%A0%E5%A5%BD%E5%8F%8B.gif?raw=true)
### 删除好友
![删除好友.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%88%A0%E9%99%A4%E5%A5%BD%E5%8F%8B.gif?raw=true)
## IM系统
### 在线聊天
#### 发送表情
![发送表情.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%8F%91%E9%80%81%E8%A1%A8%E6%83%85.gif?raw=true)
#### 发送图片、视频
![发送图片、视频.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%8F%91%E9%80%81%E5%9B%BE%E7%89%87%E3%80%81%E8%A7%86%E9%A2%91.gif?raw=true)
#### 回复
![回复.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%9B%9E%E5%A4%8D.gif?raw=true)
#### 已读
![已读.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%B7%B2%E8%AF%BB.gif?raw=true)
#### 撤回
![撤回.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E6%92%A4%E5%9B%9E.gif?raw=true)
#### 删除
![删除.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%88%A0%E9%99%A4.gif?raw=true)
#### 屏蔽
![屏蔽.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%B1%8F%E8%94%BD.gif?raw=true)
### 会话置顶与删除
![会话置顶与删除.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E4%BC%9A%E8%AF%9D%E7%BD%AE%E9%A1%B6%E4%B8%8E%E5%88%A0%E9%99%A4.gif?raw=true)
### 上线时同步消息
![上线时同步消息.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E4%B8%8A%E7%BA%BF%E6%97%B6%E5%90%8C%E6%AD%A5%E6%B6%88%E6%81%AF.gif?raw=true)
## 小程序系统
### 小程序仓库
![小程序仓库.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%B0%8F%E7%A8%8B%E5%BA%8F%E4%BB%93%E5%BA%93.gif?raw=true)
### 小程序内容推荐流（实时热榜）
![小程序内容推荐流.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%B0%8F%E7%A8%8B%E5%BA%8F%E5%86%85%E5%AE%B9%E6%8E%A8%E8%8D%90%E6%B5%81.gif?raw=true)
### 小程序向用户发送消息
![小程序向用户发送消息.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%B0%8F%E7%A8%8B%E5%BA%8F%E5%90%91%E7%94%A8%E6%88%B7%E5%8F%91%E9%80%81%E6%B6%88%E6%81%AF.gif?raw=true)
## 版本更新
### 开发者笔记
![开发者笔记.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E5%BC%80%E5%8F%91%E8%80%85%E7%AC%94%E8%AE%B0.gif?raw=true)
### 获取最新版本
![获取最新版本.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E8%8E%B7%E5%8F%96%E6%9C%80%E6%96%B0%E7%89%88%E6%9C%AC.gif?raw=true)

# 小程序一览

## 墙贴

来墙贴，贴出你的想法，随时随地表达你的分享欲。

### 有想法？贴一贴！
![有想法？贴一贴！.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/WallSticker/%E6%9C%89%E6%83%B3%E6%B3%95%EF%BC%9F%E8%B4%B4%E4%B8%80%E8%B4%B4%EF%BC%81.gif?raw=true)
### momo是谁？momo是我。
![momo是谁？momo是我。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/WallSticker/momo%E6%98%AF%E8%B0%81%EF%BC%9Fmomo%E6%98%AF%E6%88%91%E3%80%82.gif?raw=true)
### 时间线全览，发生什么，一看就懂。
![时间线全览，发生什么，一看就懂。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/WallSticker/%E6%97%B6%E9%97%B4%E7%BA%BF%E5%85%A8%E8%A7%88%EF%BC%8C%E5%8F%91%E7%94%9F%E4%BB%80%E4%B9%88%EF%BC%8C%E4%B8%80%E7%9C%8B%E5%B0%B1%E6%87%82%E3%80%82.gif?raw=true)
### 实时热点千万别错过！
![实时热点千万别错过！.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/WallSticker/%E5%AE%9E%E6%97%B6%E7%83%AD%E7%82%B9%E5%8D%83%E4%B8%87%E5%88%AB%E9%94%99%E8%BF%87%EF%BC%81.gif?raw=true)
### 多角度搜索，无处遁逃。
![多角度搜索，无处遁逃。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/WallSticker/%E5%A4%9A%E8%A7%92%E5%BA%A6%E6%90%9C%E7%B4%A2%EF%BC%8C%E6%97%A0%E5%A4%84%E9%81%81%E9%80%83%E3%80%82.gif?raw=true)

## 聊聊屋

匿名聊天室，秩序共维护。

### 今天想进哪个频道？
![今天想进哪个频道？.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/ChatRoom/%E4%BB%8A%E5%A4%A9%E6%83%B3%E8%BF%9B%E5%93%AA%E4%B8%AA%E9%A2%91%E9%81%93%EF%BC%9F.gif?raw=true)
### 微服私访，今天的身份是？
![微服私访，今天的身份是？.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/ChatRoom/%E5%BE%AE%E6%9C%8D%E7%A7%81%E8%AE%BF%EF%BC%8C%E4%BB%8A%E5%A4%A9%E7%9A%84%E8%BA%AB%E4%BB%BD%E6%98%AF%EF%BC%9F.gif?raw=true)
### 天啊，这个人真的好机车欸！
![天啊，这个人真的好机车欸！.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/ChatRoom/%E5%A4%A9%E5%95%8A%EF%BC%8C%E8%BF%99%E4%B8%AA%E4%BA%BA%E7%9C%9F%E7%9A%84%E5%A5%BD%E6%9C%BA%E8%BD%A6%E6%AC%B8%EF%BC%81.gif?raw=true)
### 双方进行了友好的私聊，充分交流了意见。
![双方进行了友好的私聊，充分交流了意见。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/ChatRoom/%E5%8F%8C%E6%96%B9%E8%BF%9B%E8%A1%8C%E4%BA%86%E5%8F%8B%E5%A5%BD%E7%9A%84%E7%A7%81%E8%81%8A%EF%BC%8C%E5%85%85%E5%88%86%E4%BA%A4%E6%B5%81%E4%BA%86%E6%84%8F%E8%A7%81%E3%80%82.gif?raw=true)

## 搭搭

搭搭，相似则聚，不合则散。

### 正在前往，搭搭广场。
![正在前往，搭搭广场。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/SeekPartner/%E6%AD%A3%E5%9C%A8%E5%89%8D%E5%BE%80%EF%BC%8C%E6%90%AD%E6%90%AD%E5%B9%BF%E5%9C%BA%E3%80%82.gif?raw=true)
### 正在发布，搭搭请求。
![正在发布，搭搭请求。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/SeekPartner/%E6%AD%A3%E5%9C%A8%E5%8F%91%E5%B8%83%EF%BC%8C%E6%90%AD%E6%90%AD%E8%AF%B7%E6%B1%82%E3%80%82.gif?raw=true)
### 正在设计，搭搭名片。
![正在设计，搭搭名片。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/SeekPartner/%E6%AD%A3%E5%9C%A8%E8%AE%BE%E8%AE%A1%EF%BC%8C%E6%90%AD%E6%90%AD%E5%90%8D%E7%89%87%E3%80%82.gif?raw=true)

## 中古

出售？求购？上中古，就对啦！

### 在淘好货，一网打尽。
![在淘好货，一网打尽。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/FleaMarket/%E5%9C%A8%E6%B7%98%E5%A5%BD%E8%B4%A7%EF%BC%8C%E4%B8%80%E7%BD%91%E6%89%93%E5%B0%BD%E3%80%82.gif?raw=true)
### 诚心求购，快速发布。
![诚心求购，快速发布。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/FleaMarket/%E8%AF%9A%E5%BF%83%E6%B1%82%E8%B4%AD%EF%BC%8C%E5%BF%AB%E9%80%9F%E5%8F%91%E5%B8%83%E3%80%82.gif?raw=true)
### 频道搜索，火眼金睛。
![频道搜索，火眼金睛。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/FleaMarket/%E9%A2%91%E9%81%93%E6%90%9C%E7%B4%A2%EF%BC%8C%E7%81%AB%E7%9C%BC%E9%87%91%E7%9D%9B%E3%80%82.gif?raw=true)
### 成交记录，帮你统计。
![成交记录，帮你统计。.gif](https://github.com/baichuanjiu/ReadMeImages/blob/main/FleaMarket/%E6%88%90%E4%BA%A4%E8%AE%B0%E5%BD%95%EF%BC%8C%E5%B8%AE%E4%BD%A0%E7%BB%9F%E8%AE%A1%E3%80%82.gif?raw=true)

# 项目架构

![项目架构.png](https://github.com/baichuanjiu/ReadMeImages/blob/main/MetaUni/%E9%A1%B9%E7%9B%AE%E6%9E%B6%E6%9E%84.png?raw=true)
图还没做好

