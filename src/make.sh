#!/bin/bash
set -e

SHELLDIR="$(dirname "$(readlink -f "$0")")"
MAKEDIR="$(dirname "$SHELLDIR")"

source "$MAKEDIR/src/env.sh"

# 检查必须的环境变量
[ "$ARCH" ] || exit 1
[ "$MIRROR" ] || exit 1


retry(){
  times="$1"
  shift
  for i in $(seq "$times"); do
    "$@" && return || err=$?
    echo "Execute failed: $@" >&2
    [ "$i" == "$times" ] && return $err
    echo "Retrying ... $i times ." >&2
  done
}

main(){
  # 检查架构对应的 pacman 的静态二进制文件
  if [ ! -f "$MAKEDIR/bin/pacman-static-$ARCH" ]; then
    echo "Not found: $MAKEDIR/bin/pacman-static-$ARCH" >&2
    exit 1
  fi

  # 建立用于 docker 的临时 rootfs 目录
  rootfs="$MAKEDIR/rootfs"
  mkdir -p "$rootfs/var"
  rm -rf "$MAKEDIR/var"
  mv "$rootfs/var" "$MAKEDIR/"
  chmod -R +w "$rootfs"
  rm -rf "$rootfs"
  mkdir -p "$rootfs"
  mv "$MAKEDIR/var" "$rootfs/"
  mkdir -m 1777 "$rootfs/tmp"
  
  # 安装 busybox-static
  install -Dm755 "$MAKEDIR/bin/busybox-static-$ARCH" \
      "$rootfs/tmp/busybox-static"
  
  # 安装 pacman-static
  install -Dm755 "$MAKEDIR/bin/pacman-static-$ARCH" \
      "$rootfs/tmp/pacman-static"
  
  # 配置 pacman-static
  install -Dm644 /dev/stdin "$rootfs/tmp/pacman-static.conf" << EOF
[options]
Architecture = auto
Color
CheckSpace
SigLevel = Never
LocalFileSigLevel = Never
[core]
Server = $MIRROR
[extra]
Server = $MIRROR
[community]
Server = $MIRROR
EOF

  # 配置软件源
  install -Dm644 /dev/stdin "$rootfs/etc/pacman.d/mirrorlist" << EOF
Server = $MIRROR
EOF
  
  # 安装脚本
  install -Dm755 "$MAKEDIR/src/install.sh" "$rootfs/tmp/install.sh"
  install -Dm644 "$MAKEDIR/src/env.sh" "$rootfs/tmp/env.sh"
  
  # 安装 ssl 证书
  install -d "$rootfs/etc/"
  cp -r /etc/ssl "$rootfs/etc/"
  cp -r /etc/ca-certificates "$rootfs/etc/"
  
  # 写 Dockerfile
  install -Dm644 /dev/stdin "$MAKEDIR/Dockerfile" << EOF
FROM scratch
COPY rootfs/ /
RUN [ "/tmp/busybox-static", "ash", "/tmp/install.sh" ]
CMD [ "/bin/su", "-", "user" ]
EOF
  
  # 下载缓存
  if type pacman > /dev/null; then
    mkdir -p "$rootfs/var/lib/pacman/" "$rootfs/var/cache/pacman/pkg/"
    retry 5 fakeroot pacman -Sy \
        --config "$rootfs/tmp/pacman-static.conf" \
        --arch "$ARCH" \
        --dbpath "$rootfs/var/lib/pacman/" \
        --cachedir "$rootfs/var/cache/pacman/pkg/" \
        --downloadonly \
        --noconfirm \
        "${INIT_PACKAGES[@]}" \
        "${PACKAGES[@]}"
  fi
  
  # 完成提示
  echo "Done. Please run ’docker build -t archlinux .’" >&2
}

main "$@"

