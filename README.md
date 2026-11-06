团子大家族

## hugo更新地址
[github](https://github.com/gohugoio/hugo/releases)
最后一个 hugo_extended_withdeploy_0.157.0_windows-amd64

## 更新主题

`themes/hugo-theme-stack/` 的完整源码由主仓库管理。克隆本项目即可获得主题文件，无需初始化子模块。
上游地址、默认分支和当前版本记录在 [hugo-theme-stack.upstream.json](themes/hugo-theme-stack.upstream.json)。

在项目根目录运行以下命令，更新到上游 `master` 分支：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-stack-theme.ps1
```

也可以指定版本，例如：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\update-stack-theme.ps1 -Ref v4.0.3
```

更新脚本要求主题目录和版本记录没有未提交改动。它会先拉取源码并备份旧主题，再替换目录、删除上游已移除的文件，并更新版本记录；备份位置会显示在终端中。
主题目录会以指定的上游版本为准，自己的模板和样式请放在项目根目录的 `layouts/`、`assets/` 中。

检查更新并构建后，把源码和版本记录一起提交：

```shell
git diff --stat
hugo --minify
git add -- themes/hugo-theme-stack themes/hugo-theme-stack.upstream.json
git commit -m "chore: update Stack theme"
```

## 查看版本
主题需要的最小版本 [theme.toml](themes/hugo-theme-stack/theme.toml) 看这个 min_version
```shell
hugo version
```

## 运行命令
```shell
hugo server -D
```

## 构建命令
```shell
hugo --gc --minify
```

```
---
title: 标题
description: 描述
date: 2026-04-02
slug: url
categories:
    - hugo
tags:
    - hugo
---
```
