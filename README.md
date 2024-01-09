# manylinux-hyperscan

![](https://github.com/darvid/manylinux-hyperscan/workflows/Publish%20Docker%20Image/badge.svg?branch=master)

This project provides an **x86_64 only** [manylinux][1]-based Docker
image with [Vectorscan][3] (a fork of [Intel Hyperscan][2]) installed.

> [!NOTE]
> As of December 13th, 2022, future tagged versions of this project will
> be indepdent of the upstream Hyperscan version, as this base image
> reflects multiple pre-requisites (most notably new Python versions) and
> not just Hyperscan.

> [!NOTE]
> As of 2024, this image defaults to installing [Vectorscan][3] instead
> of Hyperscan, due to a multiple factors, including the lack of
> multi-arch support as well as Intel's decision to move away from an
> open source license after version 5.4 (see [this issue][4] for
> context). The Dockerfile now includes two build args for configuring
> the git repo URI and ref (tag), allowing users to choose between
> Intel Hyperscan and Vectorscan if needed. However, Intel's Hyperscan
> will no longer be supported moving forward, so build functionality
> and compatibility with [python-hyperscan][5] is not guaranteed.


[1]: https://github.com/pypa/manylinux
[2]: https://github.com/intel/hyperscan
[3]: https://github.com/VectorCamp/vectorscan
[4]: https://github.com/intel/hyperscan/issues/421
[5]: https://github.com/darvid/python-hyperscan
