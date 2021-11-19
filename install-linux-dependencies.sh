#!/bin/bash
set -ex

MOZJPEG_VER=3.3.1

mkdir -p /app && cd /app

mkdir -p /build/lib && mkdir -p /build/bin

apt-get update
apt-get install -y wget libssl-dev autoconf automake libtool pkg-config nasm make

# build and install mozjpeg
wget https://github.com/mozilla/mozjpeg/archive/v$MOZJPEG_VER.tar.gz
tar -xvf v$MOZJPEG_VER.tar.gz
cd mozjpeg-$MOZJPEG_VER
autoreconf -fiv
mkdir build
cd build
sh ../configure && make install
rm /app/v$MOZJPEG_VER.tar.gz
echo "/opt/mozjpeg/lib64/" >> /etc/ld.so.conf.d/mozjpeg.conf
ldconfig
