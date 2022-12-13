# manylinux-hyperscan

![](https://github.com/darvid/manylinux-hyperscan/workflows/Publish%20Docker%20Image/badge.svg?branch=master)

This project provides an **x86_64 only** [manylinux][1]-based Docker
image with [Hyperscan][2] installed.

**Note:** As of December 13th, 2022, future tagged versions of this
project will be indepdent of the upstream Hyperscan version, as this
base image reflects multiple pre-requisites (most notably new Python
versions) and not just Hyperscan.

[1]: https://github.com/pypa/manylinux
[2]: https://github.com/intel/hyperscan
