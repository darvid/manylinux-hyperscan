ARG POLICY=manylinux2014
ARG PLATFORM=x86_64
ARG TAG=2024-01-08-eb135ed

ARG DEVTOOLSET_ROOTPATH=/opt/rh/gcc-toolset-12/root
ARG LD_LIBRARY_PATH_ARG=${DEVTOOLSET_ROOTPATH}/usr/lib64:${DEVTOOLSET_ROOTPATH}/usr/lib:${DEVTOOLSET_ROOTPATH}/usr/lib64/dyninst:${DEVTOOLSET_ROOTPATH}/usr/lib/dyninst
ARG PREPEND_PATH=${DEVTOOLSET_ROOTPATH}/usr/bin:

ARG boost_version=1.57.0
ARG build_type=MinSizeRel
ARG hyperscan_git_source=https://github.com/VectorCamp/vectorscan
ARG hyperscan_git_tag=vectorscan/5.4.11
ARG pcre_version=8.45
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

FROM base_ragel as base_vectorscan
ARG boost_version
ARG hyperscan_git_source
ARG hyperscan_git_tag
WORKDIR /tmp
RUN git clone -b ${hyperscan_git_tag} ${hyperscan_git_source}
RUN wget -qO- http://downloads.sourceforge.net/project/boost/boost/${boost_version}/boost_$(echo "${boost_version}" | tr . _).tar.bz2 | tar xj
RUN mv boost*/boost vectorscan/include

FROM base_vectorscan as build_pcre
ARG pcre_version
ENV CFLAGS="-fPIC"
WORKDIR /tmp/vectorscan
RUN wget -qO- https://sourceforge.net/projects/pcre/files/pcre/${pcre_version}/pcre-${pcre_version}.tar.gz/download | tar xvz
RUN mv pcre-${pcre_version} pcre
WORKDIR /tmp/vectorscan/pcre
RUN ./configure --prefix=/opt/pcre --enable-unicode-properties --enable-utf
RUN make -j$(nproc) && make install
RUN cp -r .libs /opt/pcre/
WORKDIR /tmp/vectorscan

FROM build_pcre AS build_vectorscan
ARG POLICY
ARG PLATFORM
ARG build_type
ARG pcre_version
RUN mkdir -p build
WORKDIR /tmp/vectorscan/build
ENV CFLAGS="-fPIC"
RUN if [[ "$POLICY" == 'musllinux_1_1' ]]; then \
  [[ "$PLATFORM" == 'aarch64' ]] && export CFLAGS="$CFLAGS -march=armv8-a" \
  || export CFLAGS="$CFLAGS -march=core2"; fi; \
  export CXXFLAGS="$CFLAGS -D_GLIBCXX_USE_CXX11_ABI=0"; \
  cmake \
  -DCMAKE_INSTALL_PREFIX=/opt/vectorscan \
  -DBUILD_STATIC_LIBS=ON \
  -DBUILD_SHARED_LIBS=ON \
  -DCMAKE_BUILD_TYPE=${build_type} \
  -DCMAKE_C_FLAGS="${CFLAGS}" \
  -DCMAKE_CXX_FLAGS="${CXXFLAGS}" \
  -DPCRE_SOURCE=../pcre \
  ../
RUN make -j$(nproc) && make install

FROM base
LABEL maintainer="David Gidwani <david.gidwani@atomweight.io>"
LABEL org.opencontainers.image.description Python manylinux with Intel Vectorscan
ARG LD_LIBRARY_PATH_ARG
ARG PREPEND_PATH
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH_ARG}
ENV PATH=${PREPEND_PATH}${PATH}
ENV PKG_CONFIG_PATH=/opt/pcre/lib/pkgconfig:/opt/vectorscan/lib/pkgconfig:/opt/vectorscan/lib64/pkgconfig:/usr/local/lib/pkgconfig
WORKDIR /opt
COPY --from=build_vectorscan /opt/pcre/ pcre
COPY --from=build_vectorscan /opt/vectorscan/ vectorscan
