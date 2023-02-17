# syzkaller - kernel fuzzer

[![CI Status](https://github.com/google/syzkaller/workflows/ci/badge.svg)](https://github.com/google/syzkaller/actions?query=workflow/ci)
[![OSS-Fuzz](https://oss-fuzz-build-logs.storage.googleapis.com/badges/syzkaller.svg)](https://bugs.chromium.org/p/oss-fuzz/issues/list?q=label:Proj-syzkaller)
[![Go Report Card](https://goreportcard.com/badge/github.com/google/syzkaller)](https://goreportcard.com/report/github.com/google/syzkaller)
[![Coverage Status](https://codecov.io/gh/google/syzkaller/graph/badge.svg)](https://codecov.io/gh/google/syzkaller)
[![GoDoc](https://godoc.org/github.com/google/syzkaller?status.svg)](https://godoc.org/github.com/google/syzkaller)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

`syzkaller` (`[siːzˈkɔːlə]`) is an unsupervised coverage-guided kernel fuzzer.\
Supported OSes: `Akaros`, `FreeBSD`, `Fuchsia`, `gVisor`, `Linux`, `NetBSD`, `OpenBSD`, `Windows`.

Mailing list: [syzkaller@googlegroups.com](https://groups.google.com/forum/#!forum/syzkaller) (join on [web](https://groups.google.com/forum/#!forum/syzkaller) or by [email](mailto:syzkaller+subscribe@googlegroups.com)).

Found bugs: [Akaros](docs/akaros/found_bugs.md), [Darwin/XNU](docs/darwin/README.md), [FreeBSD](docs/freebsd/found_bugs.md), [Linux](docs/linux/found_bugs.md), [NetBSD](docs/netbsd/found_bugs.md), [OpenBSD](docs/openbsd/found_bugs.md), [Windows](docs/windows/README.md).

## Documentation

Initially, syzkaller was developed with Linux kernel fuzzing in mind, but now
it's being extended to support other OS kernels as well.
Most of the documentation at this moment is related to the [Linux](docs/linux/setup.md) kernel.
For other OS kernels check:
[Akaros](docs/akaros/README.md),
[Darwin/XNU](docs/darwin/README.md),
[FreeBSD](docs/freebsd/README.md),
[Fuchsia](docs/fuchsia/README.md),
[NetBSD](docs/netbsd/README.md),
[OpenBSD](docs/openbsd/setup.md),
[Starnix](docs/starnix/README.md),
[Windows](docs/windows/README.md),
[gVisor](docs/gvisor/README.md).

- [How to install syzkaller](docs/setup.md)
- [How to use syzkaller](docs/usage.md)
- [How syzkaller works](docs/internals.md)
- [How to install syzbot](docs/setup_syzbot.md)
- [How to contribute to syzkaller](docs/contributing.md)
- [How to report Linux kernel bugs](docs/linux/reporting_kernel_bugs.md)
- [Tech talks and articles](docs/talks.md)
- [Research work based on syzkaller](docs/research.md)

## Usage (gramine-fuzzing)

* Running syzkaller
  * `go>=1.16` must be pre-installed.
  * [linux kernel](https://github.com/torvalds/linux) must be cloned and built under the path `$LINUX`.
  * Path to the working directory `$WORKDIR` must be set (e.g., `/syzkaller/workdir`).
```
git clone -b gramine-fuzzing https://github.com/ohblee-systems/syzkaller
cd syzkaller

# Building gramine version $VERSION (e.g., v1.3.1)
VERSION=v1.3.1
mkdir images
ln -s $PWD/tools/create-image.sh $PWD/images/
ln -s $PWD/tools/create-gramine-image.sh $PWD/images/
ln -s $PWD/tools/gramine-scripts/build-scripts/$VERSION.sh $PWD/images/

cd images
./create-gramine-image.sh -v $VERSION -k $LINUX
cd ..

# Building syzkaller
GRAMINE=1 make

# Running syzkaller using example config (i.e., tools/gramine-scripts/example.cfg)
cp tools/gramine-scripts/example.cfg ./
sed -i "s|\$LINUX|$LINUX|" example.cfg
sed -i "s|\$WORKDIR|$WORKDIR|" example.cfg
GRAMINE=1 ./bin/syz-manager -config example.cfg
```
Once the fuzzer runs, it saves the crashes into `$WORKDIR/gramine-outputs/crashes`.
`crash-<hash>.c` contains the c source triggering the bug, `crash-<hash>` is the compiled binary, and `crash-<hash>.log` contains the gramine bug log.

* Reproducing crashes
```
ln -s $PWD/tools/gramine-scripts/Makefile $WORKDIR/gramine-outputs/crashes/
ln -s $PWD/tools/gramine-scripts/crash.manifest.template $WORKDIR/gramine-outputs/crashes/

cd $WORKDIR/gramine-outputs/crashes/
make CRASH=<hash>
gramine-direct crash
```

## Disclaimer

This is not an official Google product.
