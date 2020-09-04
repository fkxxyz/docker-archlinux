#!/tmp/busybox-static ash
set -e

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

main_setup(){
  source "/tmp/env.sh"
  
  # 建立 pacman-key
  pacman-key --init
  pacman-key --populate archlinux
  
  # 安装 基础包
  retry 5 pacman -S --noconfirm "${PACKAGES[@]}"
  
  # 清理无用目录
  rm -rf /tmp/busybox-static \
      /tmp/pacman-static \
      /tmp/pacman-static.conf \
      /tmp/install.sh \
      /tmp/env.sh \
      /tmp/pkg/*
  
  # 设置 root 用户密码
  echo 'root:123456' | chpasswd
  
  # 添加一个 user 用户
  useradd -m user
  echo 'user:123456' | chpasswd
  
  # 设置 user 拥有 sudo 权限
  sed -i 's/^[[:space:]]*#*[[:space:]]*\(%wheel[[:space:]]*ALL=(ALL)[[:space:]]*ALL[[:space:]]*\(#.*\)\?\)$/\1/g' /etc/sudoers
  usermod -aG wheel user
}


main(){
  if [ -f "/bin/bash" ]; then
    main_setup
    return
  fi
  
  # 安装基本软件包
  mkdir -p /var/lib/pacman/ /var/cache/pacman/pkg/
  retry 5 /tmp/pacman-static -Sy \
      --config /tmp/pacman-static.conf \
      --overwrite \* \
      --noconfirm \
      bash \
      coreutils \
      grep \
      sed \
      gawk \
      pacman
  
  # 换成用 bash 启动该脚本
  exec /bin/bash "$0"
}

main "$@"


