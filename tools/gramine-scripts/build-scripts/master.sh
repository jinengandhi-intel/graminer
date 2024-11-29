#! /bin/bash

export http_proxy="http://proxy-dmz.intel.com:911"
export https_proxy="http://proxy-dmz.intel.com:912"

echo 'deb http://deb.debian.org/debian bullseye-backports main' > /etc/apt/sources.list.d/backports.list

# Basic dependencies
DEBIAN_FRONTEND=noninteractive apt update

DEBIAN_FRONTEND=noninteractive apt-get install -y -t bullseye-backports linux-libc-dev

DEBIAN_FRONTEND=noninteractive apt install -y \
    build-essential \
    autoconf \
    bison \
    gawk \
    nasm \
    ninja-build \
    python3 \
    python3-pip \
    python3-click \
    python3-jinja2 \
    python3-pyelftools \
    wget \
    git \
    libprotobuf-c-dev \
    protobuf-c-compiler \
    protobuf-compiler \
    python3-cryptography \
    python3-pip \
    python3-protobuf \
    python3-voluptuous \
    cmake \
    pkg-config \
    strace

python3 -m pip install  --proxy=http://proxy-dmz.intel.com:911 \
    'meson>=0.56,!=1.2.*' \
    'tomli>=1.1.0' \
    'tomli-w>=0.4.0'

DEBIAN_FRONTEND=noninteractive apt install -y \
    libunwind8 \
    musl-tools \
    python3-pytest

DEBIAN_FRONTEND=noninteractive apt install -y \
    libgmp-dev \
    libmpfr-dev \
    libmpc-dev \
    libisl-dev

# SGX dependencies
# TODO

# Build gramine
git clone https://github.com/gramineproject/gramine.git
cd gramine
meson setup build/ --buildtype=debug -Ddirect=enabled -Dsgx=enabled
ninja -C build/
ninja -C build/ install
gramine-sgx-gen-private-key -f
