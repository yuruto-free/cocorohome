FROM alpine:3.11
ARG TZ='Asia/Tokyo'

ENV TARGET_NKF=nkf-2.1.5 \
    WORKING_DIR=/work

LABEL maintainer="yuruto"

RUN    apk update \
    && apk add --no-cache tzdata jq grep \
    && cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && apk add --no-cache --virtual .build-deps \
               gcc musl-dev g++ libgcc libstdc++ libc-dev linux-headers make tar \
    && cd /tmp \
    && curl -L https://osdn.net/projects/nkf/downloads/70406/${TARGET_NKF}.tar.gz/ --output ${TARGET_NKF}.tar.gz -s \
    && tar zxvf ${TARGET_NKF}.tar.gz \
    && cd ${TARGET_NKF} \
    && make \
    && make install \
    && cd / \
    && apk --purge del .build-deps \
    && mkdir -p /config \
    && mkdir -p ${WORKING_DIR} \
    && rm -rf /tmp/${TARGET_NKF} /tmp/${TARGET_NKF}.tar.gz \
    && rm -rf /root/.cache /var/cache/apk/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY remote_IoT_device.sh /usr/local/bin/remote_IoT_device.sh
COPY start.sh /start.sh
RUN  chmod 755 /usr/local/bin/entrypoint.sh \
               /usr/local/bin/remote_IoT_device.sh \
               /start.sh

WORKDIR ${WORKING_DIR}

CMD ["/start.sh"]
