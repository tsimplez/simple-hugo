---
title: 路由器
date: 2026-04-26
slug: lyq
categories:
    - 路由器
tags:
    - 路由器
---

[upnp和dmz到底要不要一起开](https://www.right.com.cn/forum/thread-8134132-1-1.html)

## h3-2s
### 开启telnet
[开启telnet](http://192.168.1.1/usr=CMCCAdmin&psw=aDm8H%25MdA&cmd=1&telnet.gch)

#### 设备信息
- 型号：H3-2s（中兴 ZXIC，GPON 光猫）
- 系统：Linux 4.1.25+ armv7l，ZXIC CMCCV5.2.0B07（广东移动 GUD）
- 管理地址：http://192.168.1.1
- Telnet：192.168.1.1:23

#### 做了什么
1. telnet 登录后解密配置：`sidbg 1 DB decry /userconfig/cfg/db_user_cfg.xml`（明文在 /var/tmp/debug-decry-cfg）
2. 超管账号位于 `DevAuthInfo` 第 0 行（Level=1）。改密码并写盘：
    - `sidbg 1 DB set DevAuthInfo 0 Pass xxx`
    - `sidbg 1 DB save`
3. 阻止运营商（ITMS/TR-069）再下发动态密码：
    - `sidbg 1 DB set MgtServer 0 Tr069Enable 0`
    - `sidbg 1 DB set MgtServer 0 PeriodicInformEnable 0`
    - `sidbg 1 DB save`
4. 重启 Web 服务进程（httpd 以 csp 用户运行，可自行重启），让它重新加载配置、同时清掉登录失败锁定：
    - `kill <httpd_pid>`（cspd 会自动拉起新的 httpd）
#### 注意 / 回退
- 关闭 TR-069 后，移动这边将无法远程管理/下发（远程排障、自动改密、远程升级都会失效），宽带/IPTV/固话等已保存在本机，一般不受影响。
- 建议有空时把光猫断电重启一次，让 TR-069 关闭状态在整机层面彻底生效。
- 若要恢复运营商远程管理：
  `sidbg 1 DB set MgtServer 0 Tr069Enable 1`
  `sidbg 1 DB set MgtServer 0 PeriodicInformEnable 1`
  `sidbg 1 DB save`
- Web 登录的密码在前端是“大写 MD5”，脚本化登录时要注意（hexcase=1）。

#### 修改密码
sidbg 1 DB set DevAuthInfo 0 Pass xxx; sidbg 1 DB save; killall httpd

#### 其他

CMCCAdmin
user
Qqxxx@.
[参考](https://blog.csdn.net/l1677516854/article/details/136281150)
[参考](https://blog.csdn.net/cb20040401/article/details/128730222)
[参考](https://www.right.com.cn/forum/thread-7936266-1-1.html)

```shell
telnet 192.168.1.1

CMCCAdmin

aDm8H%MdA

sidbg 1 DB decry /userconfig/cfg/db_user_cfg.xml

vi /tmp/debug-decry-cfg

搜索 :/CMCCAdmin
```

[nat参考](https://blog.csdn.net/qq_46648437/article/details/113747066)

### 桥接
宽带设置

新增一个

模式 桥模式

![参考](https://cdn.242499.xyz/2026/05/17/f9b391b10c9becf19b880dafd9abd6df.png)

### 光猫改桥接后op访问光猫后台的设置
协议: DHCP 客户端
设备: wan(以太网适配器)

高级设置 使用该接口的网关作为默认网关 关闭

防火墙 选择 wan 口

https://www.bilibili.com/video/BV1F5411Q7Xp
https://zhuanlan.zhihu.com/p/1924973204142810446
创建接口 静态地址 192.168.1.x + 网关 关闭【默认网关】 有MAC就对了

## istoreos
https://fw.koolcenter.com/

[passwall](https://shdvgj.github.io/2023/07/06/2023/07/bridge-mode-starter-istoreos)

### dns
smartdns

## MER1200G
[MER1200G刷第三方固件（不需编程器和UBOOT)连WIFI就可刷机](https://www.right.com.cn/forum/forum.php?mod=viewthread&tid=8226512&highlight=MER1200G)
[水星MER1200G刷完整版operwrt 思路](https://www.right.com.cn/forum/forum.php?mod=viewthread&tid=2323889&highlight=MER1200G)
[水星MAC1200R千兆版 刷机汇总](https://www.right.com.cn/forum/thread-8263049-1-1.html)
[刷回原厂固件 ttl](https://blog.csdn.net/weixin_44658419/article/details/123284833)
[刷机教程](https://blog.csdn.net/weixin_44658419/article/details/122634305)

## 虚拟机 软路由
https://worldcovert.com/不想买软路由硬件也想体验软路由-教你如何在虚-2
