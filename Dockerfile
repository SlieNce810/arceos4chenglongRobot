FROM docker.m.daocloud.io/library/rust:bookworm

ENV RUSTUP_DIST_SERVER=https://mirrors.ustc.edu.cn/rust-static
ENV RUSTUP_UPDATE_ROOT=https://mirrors.ustc.edu.cn/rust-static/rustup

# Use domestic mirrors and avoid fallback to deb.debian.org.
RUN rm -f /etc/apt/sources.list.d/*.sources /etc/apt/sources.list.d/*.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware" > /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    echo "deb https://mirrors.aliyun.com/debian-security/ bookworm-security main contrib non-free non-free-firmware" >> /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends wget gnupg ca-certificates && \
    wget -qO- https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/bookworm/ llvm-toolchain-bookworm main" >> /etc/apt/sources.list

RUN apt-get update \
    && apt-get install -y --no-install-recommends libclang-19-dev wget make python3 \
        xz-utils python3-venv ninja-build bzip2 meson \
        pkg-config libglib2.0-dev git libslirp-dev \
    && rm -rf /var/lib/apt/lists/*

# 配置cargo使用国内镜像源
RUN mkdir -p ~/.cargo && \
    echo '[source.crates-io]' > ~/.cargo/config.toml && \
    echo 'replace-with = "ustc"' >> ~/.cargo/config.toml && \
    echo '[source.ustc]' >> ~/.cargo/config.toml && \
    echo 'registry = "https://mirrors.ustc.edu.cn/crates.io-index"' >> ~/.cargo/config.toml && \
    echo '[net]' >> ~/.cargo/config.toml && \
    echo 'git-fetch-with-cli = true' >> ~/.cargo/config.toml

COPY rust-toolchain.toml /rust-toolchain.toml

RUN rustc --version

# 使用代理下载 musl 工具链
RUN wget https://musl.cc/aarch64-linux-musl-cross.tgz \
    && wget https://musl.cc/riscv64-linux-musl-cross.tgz \
    && wget https://musl.cc/x86_64-linux-musl-cross.tgz \
    && wget https://github.com/LoongsonLab/oscomp-toolchains-for-oskernel/releases/download/loongarch64-linux-musl-cross-gcc-13.2.0/loongarch64-linux-musl-cross.tgz \
    && tar zxf aarch64-linux-musl-cross.tgz \
    && tar zxf riscv64-linux-musl-cross.tgz \
    && tar zxf x86_64-linux-musl-cross.tgz \
    && tar zxf loongarch64-linux-musl-cross.tgz \
    && rm -f *.tgz

# 使用代理下载QEMU
RUN wget https://mirror.iscas.ac.cn/qemu/v9.2.4/qemu-9.2.4.tar.xz \
    && tar xf qemu-9.2.4.tar.xz \
    && cd qemu-9.2.4 \
    && ./configure --prefix=/qemu-bin-9.2.4 \
        --target-list=loongarch64-softmmu,riscv64-softmmu,aarch64-softmmu,x86_64-softmmu \
        --enable-gcov --enable-debug --enable-slirp \
    && make -j$(nproc) \
    && make install
RUN rm -rf qemu-9.2.4 qemu-9.2.4.tar.xz

ENV PATH="/x86_64-linux-musl-cross/bin:/aarch64-linux-musl-cross/bin:/riscv64-linux-musl-cross/bin:/loongarch64-linux-musl-cross/bin:$PATH"
ENV PATH="/qemu-bin-9.2.4/bin:$PATH"