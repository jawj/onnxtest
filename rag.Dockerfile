ARG PG_VERSION=v16


FROM debian:bullseye-slim AS build-deps
RUN apt update &&  \
    apt install -y git autoconf automake libtool build-essential bison flex libreadline-dev \
    zlib1g-dev libxml2-dev libcurl4-openssl-dev libossp-uuid-dev wget pkg-config libssl-dev \
    libicu-dev libxslt1-dev liblz4-dev libzstd-dev zstd


FROM build-deps AS rust-extensions-build

RUN apt-get update && \
    apt-get install -y curl libclang-dev cmake && \
    useradd -ms /bin/bash nonroot -b /home

ENV HOME=/home/nonroot
ENV PATH="/home/nonroot/.cargo/bin:/usr/local/pgsql/bin/:$PATH"
USER nonroot
WORKDIR /home/nonroot

RUN curl -sSO https://static.rust-lang.org/rustup/dist/$(uname -m)-unknown-linux-gnu/rustup-init && \
    chmod +x rustup-init && \
    ./rustup-init -y --no-modify-path --profile minimal --default-toolchain stable && \
    rm rustup-init

USER root


FROM rust-extensions-build AS pg-onnx-build
ARG PG_VERSION

RUN apt-get update && apt-get install -y python3 python3-pip && \
    python3 -m pip install cmake && \
    wget https://github.com/microsoft/onnxruntime/archive/refs/tags/v1.19.2.tar.gz -O onnxruntime.tar.gz && \
    mkdir onnxruntime-src && cd onnxruntime-src && tar xzf ../onnxruntime.tar.gz --strip-components=1 -C . && \
    ./build.sh --config Release --parallel --skip_submodule_sync --skip_tests --allow_running_as_root


FROM pg-onnx-build AS pg-neon-ai-pg-build
ARG PG_VERSION

RUN wget https://github.com/jawj/onnxtest/archive/refs/heads/main.tar.gz -O pg_neon_ai.tar.gz && \
    mkdir pg_neon_ai-src && cd pg_neon_ai-src && tar xzf ../pg_neon_ai.tar.gz --strip-components=1 -C . && \
    cd bge_small_en_v15 && tar xzf model.onnx.tar.gz && cd .. && \
    cd jina_reranker_v1_tiny_en && tar xzf model.onnx.tar.gz && cd .. && \
    ORT_LIB_LOCATION=/home/nonroot/onnxruntime-src/build/Linux cargo run && \
    sleep 30

