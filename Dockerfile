ARG POLICY=manylinux2014
ARG PLATFORM=x86_64
ARG TAG=2023-07-17-129380e

ARG DEVTOOLSET_ROOTPATH=/opt/rh/gcc-toolset-12/root
ARG LD_LIBRARY_PATH_ARG=${DEVTOOLSET_ROOTPATH}/usr/lib64:${DEVTOOLSET_ROOTPATH}/usr/lib:${DEVTOOLSET_ROOTPATH}/usr/lib64/dyninst:${DEVTOOLSET_ROOTPATH}/usr/lib/dyninst
ARG PREPEND_PATH=${DEVTOOLSET_ROOTPATH}/usr/bin:

ARG boost_version=1.57.0
ARG build_type=Release
ARG hyperscan_version=v5.4.2
ARG pcre_version=10.42
ARG ragel_version=6.10

FROM quay.io/pypa/${POLICY}_${PLATFORM}:${TAG} AS base
ARG POLICY
RUN if [ "$POLICY" == 'musllinux_1_1' ]; then apk --update add gcc wget ; else yum install -y gcc wget; fi

FROM base AS base_ragel
ARG POLICY
ARG ragel_version
WORKDIR /tmp
RUN if [ "$POLICY" == 'musllinux_1_1' ]; then apk --update add git ; else yum install -y git; fi
RUN wget -qO- https://www.colm.net/files/ragel/ragel-${ragel_version}.tar.gz | tar -vxz
WORKDIR /tmp/ragel-${ragel_version}
RUN ./configure --prefix=/usr && make -j$(nproc) && make install

FROM base_ragel as base_hyperscan
ARG boost_version
ARG hyperscan_version
WORKDIR /tmp
RUN git clone -b ${hyperscan_version} https://github.com/01org/hyperscan.git
RUN wget -qO- http://downloads.sourceforge.net/project/boost/boost/${boost_version}/boost_$(echo "${boost_version}" | tr . _).tar.bz2 | tar xj
RUN mv boost*/boost hyperscan/include

FROM base_hyperscan as build_pcre
ARG pcre_version
ENV CFLAGS="-fPIC"
WORKDIR /tmp/hyperscan
RUN wget -qO- https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${pcre_version}/pcre2-${pcre_version}.tar.gz | tar xvz
WORKDIR /tmp/hyperscan/pcre2-${pcre_version}
RUN ./configure --prefix=/opt/pcre --enable-unicode-properties --enable-utf
RUN make -j$(nproc) && make install
RUN cp -r .libs /opt/pcre/
WORKDIR /tmp/hyperscan

FROM build_pcre AS build_hyperscan
ARG build_type
ARG pcre_version
RUN mkdir -p build
WORKDIR /tmp/hyperscan/build
ENV CFLAGS="-fPIC"
ENV CXXFLAGS="$CFLAGS -D_GLIBCXX_USE_CXX11_ABI=0"
RUN cmake \
  -DCMAKE_INSTALL_PREFIX=/opt/hyperscan \
  -DFAT_RUNTIME=ON \
  -DBUILD_STATIC_AND_SHARED=ON \
  -DCMAKE_BUILD_TYPE=${build_type} \
  -DPCRE_SOURCE=../pcre-${pcre_version} \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  ../
RUN make -j$(nproc) && make install

FROM base
ARG LD_LIBRARY_PATH_ARG
ARG PREPEND_PATH
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH_ARG}
ENV PATH=${PREPEND_PATH}${PATH}
ENV PKG_CONFIG_PATH=/opt/pcre/lib/pkgconfig:/opt/hyperscan/lib64/pkgconfig:/usr/local/lib/pkgconfig
LABEL maintainer="David Gidwani <david.gidwani@gmail.com>"
WORKDIR /opt
COPY --from=build_hyperscan /opt/pcre/ pcre
COPY --from=build_hyperscan /opt/hyperscan/ hyperscan
