#!/bin/bash
set -ex

MOZJPEG_VER=4.1.5

mkdir -p /app && cd /app

apt-get update
apt-get install -y wget cmake libssl-dev libpng-dev pkg-config nasm make

# build and install mozjpeg
wget -q https://github.com/mozilla/mozjpeg/archive/refs/tags/v$MOZJPEG_VER.tar.gz
tar -xf v$MOZJPEG_VER.tar.gz
cd mozjpeg-$MOZJPEG_VER
mkdir build && cd build
cmake -G"Unix Makefiles" -DCMAKE_INSTALL_PREFIX=/opt/mozjpeg ..
make -j"$(nproc)"
make install
cd /app
rm -rf /app/v$MOZJPEG_VER.tar.gz /app/mozjpeg-$MOZJPEG_VER

# mozjpeg 4.x installs into lib (not lib64) on most platforms; ensure both work
if [ -d /opt/mozjpeg/lib64 ]; then
  echo "/opt/mozjpeg/lib64/" > /etc/ld.so.conf.d/mozjpeg.conf
else
  echo "/opt/mozjpeg/lib/" > /etc/ld.so.conf.d/mozjpeg.conf
  # Provide lib64 symlink so Makefile/Package.swift paths (which use lib64 on Linux) still work
  ln -sfn /opt/mozjpeg/lib /opt/mozjpeg/lib64
fi
ldconfig
