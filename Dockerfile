FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    tcl8.6 \
    libreadline-dev \
    libncurses-dev \
    zlib1g-dev \
    git \
    ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# liburing isn't packaged for this base image; build it from source.
RUN git clone --depth 1 --branch liburing-2.6 https://github.com/axboe/liburing.git /tmp/liburing \
 && cd /tmp/liburing && ./configure && make -j"$(nproc)" && make install && ldconfig \
 && rm -rf /tmp/liburing

WORKDIR /opt/EMSOFT2026
COPY . .

# init_construct_fin_table_src: construction-only engine (CREATE/INSERT + .finconstruct)
RUN cd init_construct_fin_table_src \
 && mkdir -p bld && cd bld \
 && ../configure \
 && make -j"$(nproc)" sqlite3

# SQLite-LAP: io_uring + thread-pool prefetch engine (read-only experiments)
RUN cd SQLite-LAP \
 && mkdir -p bld && cd bld \
 && ../configure \
 && sed -i '/^CFLAGS = /s/$/ -pthread/' Makefile \
 && sed -i '/^CFLAGS = /a LIBS += -luring -pthread' Makefile \
 && make -j"$(nproc)" sqlite3

RUN ln -s /opt/EMSOFT2026/init_construct_fin_table_src/bld/sqlite3 /usr/local/bin/sqlite3-construct \
 && ln -s /opt/EMSOFT2026/SQLite-LAP/bld/sqlite3 /usr/local/bin/sqlite3-lap

WORKDIR /data
CMD ["/bin/bash"]
