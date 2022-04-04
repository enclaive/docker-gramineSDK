# ubuntu 21.10 and intel/linux-sgx 0af6a83e
FROM ubuntu:impish

# set to noninteractive for debconf, just in case
ENV DEBIAN_FRONTEND noninteractive

COPY linux-sgx/packages.txt .
RUN apt-get update && xargs -a packages.txt -r apt-get install -y
RUN useradd -m user

USER user
WORKDIR /home/user

RUN git clone https://github.com/intel/linux-sgx.git
WORKDIR ./linux-sgx
RUN git checkout 0af6a83e

RUN make preparation

USER root
RUN cp external/toolset/ubuntu20.04/* /usr/local/bin

USER user
RUN make sdk_install_pkg DEBUG=1
RUN ./linux/installer/bin/sgx_linux_x64_sdk_2.15.101.1.bin --prefix install

USER root
RUN mv install/ /opt/intel

USER user
COPY linux-sgx/patch.diff .
RUN git apply patch.diff

RUN cd psw/ae/le/ && make && cd ../pve/ && make && cd ../pce/ && make && cd ../qe/ && make

COPY linux-sgx/external.diff .
RUN git apply external.diff
RUN make deb_local_repo DEBUG=1

USER root
RUN mv linux/installer/deb/sgx_debian_local_repo/ /opt/
COPY linux-sgx/intel-sgx-psw.list /etc/apt/sources.list.d

ENTRYPOINT [ "/bin/bash" ]
