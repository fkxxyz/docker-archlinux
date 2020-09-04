## 简介

由于官方镜像的 archlinux docker 镜像总是不是最新的，每次拉去下来还要自己又更新成最新的，是一种资源的浪费。此项目用于从零开始快速生成一个最新的 archlinux 的 docker 镜像的脚本。

## 用法

使用前，需要将一些编译好的二进制文件放到项目的 bin 目录

| 程序             | 架构    | 放入路径                   |
| ---------------- | ------- | -------------------------- |
| pacman （静态）  | x86_64  | bin/pacman-static-x86_64   |
| pacman （静态）  | aarch64 | bin/pacman-static-aarch64  |
| busybox （静态） | x86_64  | bin/busybox-static-x86_64  |
| busybox （静态） | aarch64 | bin/busybox-static-aarch64 |

其它架构同理，想要构建什么，就只需要对应的架构的二进制文件即可



然后开始构建临时根目录 （会生成 rootfs目录 和 Dockerfile，ARCH 环境变量将会影响构建的架构，默认为当前系统架构，详见 src/env.sh）

```shell
make

# 或指定架构构建
make ARCH=aarch64
```

构建 docker 镜像

```shell
make install
```

查看构建的 nde 镜像

```
docker image ls
```

