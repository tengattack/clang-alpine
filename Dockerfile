FROM alpine:3.12

WORKDIR /build

COPY . .

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories \
    && ./download.sh

RUN ./build.sh stage0

RUN ./build.sh stage1

RUN ./build.sh stage2
