#!/bin/bash
set -e

echo "Setting up ArceOS development environment..."

# Update system packages
apt-get update
apt-get install -y --no-install-recommends \
    libclang-19-dev \
    wget \
    make \
    python3 \
    python3-pip \
    xz-utils \
    python3-venv \
    ninja-build \
    bzip2 \
    meson \
    pkg-config \
    libglib2.0-dev \
    git \
    libslirp-dev \
    qemu-user-static \
    qemu-system-arm \
    qemu-system-x86 \
    qemu-system-riscv64 \
    gcc-multilib \
    g++-multilib

# Install Rust nightly components
rustup component add rust-src llvm-tools rustfmt clippy
rustup toolchain install nightly-2025-05-20
rustup default nightly-2025-05-20

# Add cross-compilation targets
rustup target add x86_64-unknown-none
rustup target add riscv64gc-unknown-none-elf
rustup target add aarch64-unknown-none-softfloat
rustup target add loongarch64-unknown-none-softfloat

# Install cargo tools
cargo install cargo-binutils
cargo install axconfig-gen
cargo install cargo-axplat

# Download and setup cross-compilation toolchains
echo "Downloading cross-compilation toolchains..."
cd /tmp
wget -q https://musl.cc/aarch64-linux-musl-cross.tgz &
wget -q https://musl.cc/riscv64-linux-musl-cross.tgz &
wget -q https://musl.cc/x86_64-linux-musl-cross.tgz &
wget -q https://github.com/LoongsonLab/oscomp-toolchains-for-oskernel/releases/download/loongarch64-linux-musl-cross-gcc-13.2.0/loongarch64-linux-musl-cross.tgz &
wait

echo "Extracting toolchains..."
tar zxf aarch64-linux-musl-cross.tgz -C /
tar zxf riscv64-linux-musl-cross.tgz -C /
tar zxf x86_64-linux-musl-cross.tgz -C /
tar zxf loongarch64-linux-musl-cross.tgz -C /
rm -f *.tgz

# Update PATH in shell config
echo 'export PATH="/x86_64-linux-musl-cross/bin:/aarch64-linux-musl-cross/bin:/riscv64-linux-musl-cross/bin:/loongarch64-linux-musl-cross/bin:$PATH"' >> /root/.bashrc

echo "ArceOS development environment setup complete!"
rustc --version
cargo --version
