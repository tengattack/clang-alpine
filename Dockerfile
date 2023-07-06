FROM debian:buster-slim

WORKDIR /build

COPY . .

RUN sed -i -e 's#http://deb.debian.org#http://mirrors.aliyun.com#g' \
      -e 's#http://security.debian.org#http://mirrors.aliyun.com#g' \
      /etc/apt/sources.list \
    && apt-get update \
    && ./download.sh

RUN ./build.sh stage0

RUN ./build.sh stage1

RUN ./build.sh stage2
