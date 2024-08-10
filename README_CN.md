# am-nodejs-proxy
https://github.com/ansoncloud8/am-nodejs-proxy

基于 Node.js 的 vless 实现包。它在各种 Node.js 环境中都能运行，包括但不限于：Windows、Linux、MacOS、Android、iOS、树莓派等。同时，它也适用于各种 PaaS 平台，如：replit、heroku 等。

- [中文文档](./README_CN.md) 
- [视频教程](https://youtu.be/tj9uD575R80)

- 官网教程：[AM科技](https://am.809098.xyz)
- YouTube频道：[@AM_CLUB](https://youtube.com/@AM_CLUB)
- Telegram交流群：[@AM_CLUBS](https://t.me/AM_CLUBS)
- 免费订阅：[进群发送关键字: 订阅](https://t.me/AM_CLUBS)


本自述文件解释了如何设置和使用“start.sh”脚本来管理项目组件。

## 初始设置

1. 使用 SSH 连接到您的主机：

```
ssh <username>@<panel>.serv00.com
```

使用 serv00 通过电子邮件发送给您的信息,上面的username、panel换成你接收的信息。

2. 启用管理权限：

```
devil binexec on
```

***完成此步骤后，退出 SSH 并再次登录。***

3. 克隆仓库代码：

```
cd domains/${USER}.serv00.net
```
```
git clone https://github.com/ansoncloud8/am-nodejs-proxy.git
```
```
cd am-nodejs-proxy
```

## 使用

要使用该脚本，请运行：

```
./start.sh <action> <sub-action>
```

| Action |  Sub-Action   |         Command         |                  Description                   |
| :----: | :-----------: | :---------------------: | :--------------------------------------------: |
| setup  |   node/xray/cf   | `./start.sh setup node` |      通过单个命令设置服务       |
| check  |   node/xray/cf   | `./start.sh check node` |    检查 Cloudflared 和其他服务      |
|  show  | node/xray/all | `./start.sh show node`  | 显示来自 node/.env 的 VLESS 连接链接 |

查看所有节点信息
```
cat domains/${USER}.serv00.net/am-nodejs-proxy/node/.env
```

***NODE.JS 和 XRAY 不能同时处于活动状态。一次只能运行其中一个。***

## 检查会话

要检查特定组件的状态，您可以附加到其 tmux 会话：

```
tmux attach -t <session>
```

将 `<session>` 替换为：

- `cf` for Cloudflared
- `node` for Node.js
- `xray` for Xray

例如，要检查 Cloudflared 会话：

```
tmux attach -t cf
```

要从 tmux 会话分离而不关闭它，请按：

```
Ctrl + b, 然后是 d
```

此组合键允许您退出会话，同时使其在后台运行。

## Notes

- 该脚本使用 tmux 来管理每个组件的会话。
- 设置 Cron 作业用于定期维护 Node.js 和 Xray。
- Cloudflared、Node.js 和 Xray 配置自动生成。
- 该脚本包括端口管理和清理功能。

 #
▶️ **新人[YouTube](https://youtube.com/@AM_CLUB)** 需要您的支持，请务必帮我**点赞**、**关注**、**打开小铃铛**，***十分感谢！！！*** ✅
</br>🎁 不要只是下载或Fork。请 **follow** 我的GitHub、给我所有项目一个 **Star** 星星（拜托了）！你的支持是我不断前进的动力！ 💖
  
 # 
<center><details><summary><strong> [点击展开] 赞赏支持 ~🧧</strong></summary>
*我非常感谢您的赞赏和支持，它们将极大地激励我继续创新，持续产生有价值的工作。*
  
- **USDT-TRC20:** `TWTxUyay6QJN3K4fs4kvJTT8Zfa2mWTwDD`
  
</details></center>


