FROM quay.io/pypa/manylinux1_x86_64
LABEL maintainer="David Gidwani <david.gidwani@gmail.com>"
ARG boost_dist_url=http://downloads.sourceforge.net/project/boost/boost/1.57.0/boost_1_57_0.tar.bz2
ARG hyperscan_tag=v5.2.1
ARG ragel_version=6.10
RUN yum install -y gcc git wget && \
  /opt/python/cp27-cp27mu/bin/pip install cmake && \
  cd /tmp && \
  wget --secure-protocol=TLSv1 https://www.colm.net/files/ragel/ragel-${ragel_version}.tar.gz && \
  tar xzf ragel-${ragel_version}.tar.gz && \
  cd ragel-${ragel_version} && \
  ./configure --prefix=/usr && \
  make && \
  make install && \
  cd .. && \
  wget --secure-protocol=TLSv1 ${boost_dist_url} && \
  tar xjf boost*.tar.bz2 && \
  git clone https://github.com/01org/hyperscan.git && \
  mv boost*/boost hyperscan/include && \
  mkdir -p hyperscan/build
RUN cd /tmp/hyperscan/build && \
  git checkout ${hyperscan_tag} && \
  /opt/python/cp27-cp27mu/bin/cmake \
    -DCMAKE_INSTALL_PREFIX:PATH=/usr \
    -DBUILD_SHARED_LIBS=ON \
    -G "Unix Makefiles" \
    ../ && \
  make && \
  make install && \
  cd / && \
  rm -rf /tmp/* && \
  yum -y remove gcc git
