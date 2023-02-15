#! /bin/bash

# Basic dependencies

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
    git

python3 -m pip install \
    'meson>=0.56' \
    'toml>=0.10'

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
# git clone -b v1.3.1 https://github.com/gramineproject/gramine.git
cd gramine
meson setup build/ --buildtype=debug -Ddirect=enabled -Dsgx=disabled
ninja -C build/
ninja -C build/ install
