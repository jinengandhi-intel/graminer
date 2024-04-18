#!/usr/bin/env bash

CREATE_IMG=create-image.sh
QEMU=qemu-system-x86_64
NC=nc

RELEASE=bullseye
VERSION=v1.5


if [ ! -f $CREATE_IMG ]; then
    echo "Error: ${CREATE_IMG} does not exist"
    exit 1
elif [ -z $(command -v $QEMU) ]; then
    echo "Error: ${QEMU} is not installed"
    exit 1
elif [ -z $(command -v $NC) ]; then
    echo "Error: ${NC} is not installed"
    exit 1
fi

display_help() {
    echo "Usage: $0 [option...] " >&2
    echo
    echo "   -v, --version               Set Gramine version"
    echo "   -k, --kernel                Path to the linux kernel source directory"
    echo
}

wait_port() {
    p=$1

    while ! $NC -z 127.0.0.1 $p; do
        sleep 1
    done

    sleep 1
}

while true; do
    if [ $# -eq 0 ]; then
        echo $#
        break
    fi
    case "$1" in
        -h | --help)
            display_help
            exit 0
            ;;
        -v | --version)
            VERSION=$2
            shift 2
            ;;
        -k | --kernel)
            KERNEL=$2
            shift 2
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *) # No more options
            break
            ;;
    esac
done

if [ -z $KERNEL ]; then
    echo "Error: path to the linux kernel source directory is not set"
    exit 1
elif [ ! -f $KERNEL/arch/x86/boot/bzImage ]; then
    echo "Error: kernel image is not built"
    exit 1
elif [ ! -f $VERSION.sh ]; then
    echo "Error: $VERSION.sh does not exist"
    exit 1
fi


if [ ! -f $RELEASE.img ]; then
    ./$CREATE_IMG -d $RELEASE -s 131072
fi

if [[ $(qemu-system-x86_64 -cpu help | xargs printf "%s\n" | grep sgx) ]]; then
    HOST_PARAMS='host,+sgx,+sgx-debug,+sgx-exinfo,+sgx-kss,+sgx-mode64,+sgx-provisionkey,+sgx-tokenkey,+sgx1,+sgx2,+sgxlc -M sgx-epc.0.memdev=mem1 -object memory-backend-epc,id=mem1,size=64M,prealloc=on'
else
    HOST_PARAMS='host'
fi

echo "Running qemu..."
$QEMU \
    -cpu $HOST_PARAMS \
    -m 32G \
    -smp 12 \
    -kernel $KERNEL/arch/x86/boot/bzImage \
    -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0" \
    -drive file=$RELEASE.img,format=raw \
    -net user,host=10.0.2.10,hostfwd=tcp:127.0.0.1:10021-:22 \
    -net nic,model=e1000 \
    -enable-kvm \
    -nographic \
    -pidfile vm.pid \
    2>&1 | tee vm.log &

wait_port 10021

sleep 30s

echo "Building gramine..."
ssh-keygen -f "$HOME/.ssh/known_hosts" -R "[localhost]:10021"
scp -i $RELEASE.id_rsa -P 10021 -o "StrictHostKeyChecking no" $VERSION.sh root@localhost:/root/
ssh -i $RELEASE.id_rsa -p 10021 -o "StrictHostKeyChecking no" root@localhost "./$VERSION.sh && export http_proxy=http://proxy-dmz.intel.com:911 && export https_proxy=http://proxy-dmz.intel.com:912 && apt install -y clang-format && poweroff -f"
