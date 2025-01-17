FROM debian:jessie as builder

ARG BUILD_THREADS=4

ENV PATH=/usr/local/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib

RUN cat /etc/apt/sources.list | sed "s/deb /deb-src /g" >> /etc/apt/sources.list \
    && sed -i "s/ main/ main contrib/g" /etc/apt/sources.list \
    && apt-get update \
    && apt-get -y install \
        build-essential \
        git \
        wget

RUN apt-get -y build-dep \
        gcc \
    && apt-get -y install \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
    && cd /tmp \
    && wget ftp://ftp.uvsq.fr/pub/gcc/releases/gcc-6.4.0/gcc-6.4.0.tar.gz \
    && tar xvf gcc-6.4.0.tar.gz \
    && cd gcc-6.4.0 \
    && ./configure \
        --program-suffix=-6 \
        --enable-languages=c,c++ \
        --disable-multilib \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/gcc-6.4.0* \
    && update-alternatives \
        --install /usr/bin/gcc gcc /usr/local/bin/gcc-6 60 \
        --slave /usr/bin/g++ g++ /usr/local/bin/g++-6

RUN apt-get -y build-dep \
        cmake \
    && cd /tmp \
    && git clone https://github.com/Kitware/CMake.git cmake \
    && cd cmake \
    && git checkout tags/v3.5.2 \
    && ./configure \
        --prefix=/usr/local \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/cmake

RUN apt-get -y build-dep \
        libboost-all-dev \
    && apt-get -y install \
        python-dev \
    && cd /tmp \
    && wget https://dl.bintray.com/boostorg/release/1.64.0/source/boost_1_64_0.tar.gz \
    && tar xvf boost_1_64_0.tar.gz \
    && cd boost_1_64_0 \
    && ./bootstrap.sh \
        --with-libraries=program_options,filesystem,system \
        --prefix=/usr/local \
    && ./b2 -j ${BUILD_THREADS} install \
    && rm -rf /tmp/boost_1_64_0*

RUN apt-get -y build-dep \
        libmygui-dev \
    && apt-get -y install \
        libfreetype6-dev \
    && cd /tmp \
    && git clone https://github.com/MyGUI/mygui.git mygui \
    && cd mygui \
    && git checkout 82fa8d4fdcaa06cf96dfec8a057c39cbaeaca9c \
    && mkdir build \
    && cd build \
    && cmake \
        -DMYGUI_RENDERSYSTEM=1 \
        -DMYGUI_BUILD_DEMOS=OFF \
        -DMYGUI_BUILD_TOOLS=OFF \
        -DMYGUI_BUILD_PLUGINS=OFF \
        -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/mygui

RUN apt-get -y build-dep \
        libopenscenegraph-dev \
    && cd /tmp \
    && git clone -b 3.4 https://github.com/OpenMW/osg.git \
    && cd osg \
    && mkdir build \
    && cd build \
    && cmake \
        -DBUILD_OSG_PLUGINS_BY_DEFAULT=0 \
        -DBUILD_OSG_PLUGIN_OSG=1 \
        -DBUILD_OSG_PLUGIN_DDS=1 \
        -DBUILD_OSG_PLUGIN_TGA=1 \
        -DBUILD_OSG_PLUGIN_BMP=1 \
        -DBUILD_OSG_PLUGIN_JPEG=1 \
        -DBUILD_OSG_PLUGIN_PNG=1 \
        -DBUILD_OSG_DEPRECATED_SERIALIZERS=0 \
        -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/osg

RUN apt-get -y install \
        libfontconfig1-dev \
        libfreetype6-dev \
        libx11-dev \
        libxext-dev \
        libxfixes-dev \
        libxi-dev \
        libxrender-dev \
        libxcb1-dev \
        libx11-xcb-dev \
        libxcb-glx0-dev \
        libxcb-keysyms1-dev \
        libxcb-image0-dev \
        libxcb-shm0-dev \
        libxcb-icccm4-dev \
        libxcb-sync0-dev \
        libxcb-xfixes0-dev \
        libxcb-shape0-dev \
        libxcb-randr0-dev \
        libxcb-render-util0-dev \
    && cd /tmp \
    && git clone git://code.qt.io/qt/qt5.git \
    && cd qt5 \
    && git checkout 5.5 \
    && ./init-repository \
    && yes | ./configure \
        -opensource \
        -nomake examples \
        -nomake tests \
        --prefix=/usr/local \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/qt5

RUN apt-get -y install \
        libvorbis-dev \
        libmp3lame-dev \
        libopus-dev \
        libtheora-dev \
        libspeex-dev \
        yasm \
        pkg-config \
        libopenjpeg-dev \
        libx264-dev \
    && cd /tmp \
    && git clone https://github.com/FFmpeg/FFmpeg.git ffmpeg \
    && cd ffmpeg \
    && ./configure \
        --prefix=/usr/local \
        --enable-shared \
        --enable-gpl \
        --enable-libvorbis \
        --enable-libtheora \
        --enable-libmp3lame \
        --enable-libopus \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/ffmpeg

RUN apt-get -y build-dep \
        bullet \
    && cd /tmp \
    && git clone https://github.com/bulletphysics/bullet3.git bullet \
    && cd bullet \
    && git checkout tags/2.86 \
    && rm -f CMakeCache.txt \
    && mkdir build \
    && cd build \
    && cmake \
        -DBUILD_SHARED_LIBS=1 \
        -DINSTALL_LIBS=1 \
        -DINSTALL_EXTRA_LIBS=1 \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr/local .. \
    && make -j ${BUILD_THREADS} \
    && make install \
    && rm -rf /tmp/bullet

FROM debian:jessie

LABEL maintainer="Grim Kriegor <grimkriegor@krutt.org>"
LABEL description="A container to simplify the packaging of TES3MP for GNU/Linux"

ARG BUILD_THREADS=4
ENV BUILD_THREADS=${BUILD_THREADS}

ENV PATH=/usr/local/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib64:/usr/local/lib

COPY --from=builder /usr/local /usr/local

RUN apt-get update \
    && apt-get -y install \
        build-essential \
        git \
        wget \
        lsb-release \
        unzip \
        libopenal-dev \
        libsdl2-dev \
        libunshield-dev \
        libncurses5-dev \
        libluajit-5.1-dev \
        libpng12-0 \
        libopus0 \
        libmp3lame0 \
        libtheora0 \
        libfreetype6 \
    && update-alternatives \
        --install /usr/bin/gcc gcc /usr/local/bin/gcc-6 60 \
        --slave /usr/bin/g++ g++ /usr/local/bin/g++-6

RUN git config --global user.email "nwah@mail.com" \
    && git config --global user.name "N'Wah" \
    && git clone https://github.com/GrimKriegor/TES3MP-deploy.git /deploy \
    && mkdir /build

VOLUME [ "/build" ]
WORKDIR /build

ENTRYPOINT [ "/bin/bash", "/deploy/tes3mp-deploy.sh", "--script-upgrade", "--cmake-local", "--skip-pkgs", "--handle-corescripts" ]
CMD [ "--install", "--make-package" ]
