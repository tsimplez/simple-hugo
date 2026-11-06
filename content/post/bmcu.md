---
title: 团子 bmcu-esp
date: 2026-11-06
slug: bmcu
categories:
    - bmcu
tags:
    - bmcu
---

- [qq群 1093447641](https://qm.qq.com/q/NMvaApOeY2)
- [仓库 https://github.com/tsimplez/bmcu-esp](https://github.com/tsimplez/bmcu-esp)
- [pcb https://oshwhub.com/tz_simple/project_vsifmgrt](https://oshwhub.com/tz_simple/project_vsifmgrt)
- [挤出机模型地址 https://makerworld.com.cn/zh/models/3120969](https://makerworld.com.cn/zh/models/3120969)

## BOM清单
### 必须
| 品名 | 参考图  | 数量 | 说明 |
|---|---|---|---|
| esp32 | ![esp32c3](/bmcu/esp32c3.jpeg) | 1 | 简约 和 经典 都可以 | 
| RS485模块 TTL转RS485 | ![485.png](/bmcu/485.png) ![485de](/bmcu/485de.png) | 1 | 两种都可以 |
| PCF8575 | ![PCF8575.png](/bmcu/PCF8575.png) | 2 | 一个就是4色 两个就是8色 3个12色 4个16色 |
| DRV8833电机驱动 | ![DRV8833.png](/bmcu/DRV8833.png) | 4 | 一个控制两个电机 |
| TT电机 1/48黑头单轴 | ![tt电机](/bmcu/tt.png) | 8 | 白头应该也可以 几色就几个 |
| 压板弹簧外径5*长度10*线径0.4 |  | 8 | 无所谓，长了就剪 |
| M3沉头螺丝 |  | * | 推荐每个规格都买(平时也用的到) 一种的话推荐(M3*20) |

### 可选
| 品名 | 参考图  | 数量 | 说明 |
|---|---|---|---|
| 三脚带柄13.5mm按键微动 | ![wd.png](/bmcu/wd.png) | 8 | 可以不要 功能(可自吸和耗材在线检测) 至少一个电机一个|
| AMS数据线（4pin公对公，原厂线序，不是延长线） | ![线](/bmcu/ams.png) | 1 | 杜邦线也不是不能用 打印机ams接口是(上左 B 上右 A 下左 GND 下右 24V)和485模块的关系是(A接A B接B) | 
| MX3 2*2 弯针座 | ![amsm.png](/bmcu/amsm.png) | 1 | AMS数据线接口 |
| mini 5V电源模块 | ![电源](/bmcu/dy.png) | 1 | 不用也可以 用手机数据线(type-c)接esp32 |
| 2.54排母，要4P 5P 6P 10P 16P 可以直接买一份1x40P的自己剪断 | ![pm.png](/bmcu/pm.png) | * | 不要也可以 直接焊接到pcb上(不方便拆) 买2P和3P组合使用也可以|
| xh2.54直针插座| ![xh.png](/bmcu/xh.png) | * | 一个电机一个 |
| 温湿度模块|  | * | 可选|
