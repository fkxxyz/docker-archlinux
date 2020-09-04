
# 处理环境变量
[ "$ARCH" ] || export ARCH="$(uname -m)"

# 处理软件源
if [ ! "$MIRROR" ]; then
  if [ "$ARCH" == "x86_64" ]; then
    export MIRROR='https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch'
  else
    export MIRROR='https://mirrors.tuna.tsinghua.edu.cn/archlinuxarm/$arch/$repo'
  fi
fi

export INIT_PACKAGES=(
  bash
  coreutils
  grep
  sed
  gawk
  pacman
)

export PACKAGES=(
  systemd
  util-linux
  shadow
  sudo
  vim
)


