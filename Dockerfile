FROM golang:alpine

# Update
RUN apk update upgrade;

# Install git
RUN apk add git

# Set timezone to Europe/Zurich
RUN apk add tzdata
RUN ln -s /usr/share/zoneinfo/Europe/Zurich /etc/localtime

# Install ClamAV
RUN apk --no-cache add clamav clamav-libunrar \
    && mkdir /run/clamav \
    && chown clamav:clamav /run/clamav

# Configure clamAV to run in foreground with port 3310
RUN sed -i 's/^#Foreground .*$/Foreground true/g' /etc/clamav/clamd.conf \
    && sed -i 's/^#TCPSocket .*$/TCPSocket 3310/g' /etc/clamav/clamd.conf \
    && sed -i 's/^#Foreground .*$/Foreground true/g' /etc/clamav/freshclam.conf

RUN freshclam --quiet --no-dns

# Build go package
ADD . /go/src/clamav-rest/
RUN go get github.com/dutchcoders/go-clamd
RUN go get github.com/prometheus/client_golang/prometheus/promhttp
ADD ./server.* /etc/ssl/clamav-rest/
RUN cd /go/src/clamav-rest && go build -v

COPY entrypoint.sh /usr/bin/
RUN mv /go/src/clamav-rest/clamav-rest /usr/bin/ && rm -Rf /go/src/clamav-rest

COPY clamav-freshclam.cron /etc/cron.d/clamav-freschclam

EXPOSE 9000
EXPOSE 9443

ENV MAX_SCAN_SIZE=100M
ENV MAX_FILE_SIZE=25M
ENV MAX_RECURSION=16
ENV MAX_FILES=10000
ENV MAX_EMBEDDEDPE=10M
ENV MAX_HTMLNORMALIZE=10M
ENV MAX_HTMLNOTAGS=2M
ENV MAX_SCRIPTNORMALIZE=5M
ENV MAX_ZIPTYPERCG=1M
ENV MAX_PARTITIONS=50
ENV MAX_ICONSPE=100
ENV PCRE_MATCHLIMIT=100000
ENV PCRE_RECMATCHLIMIT=2000
ENV SIGNATURE_CHECKS=24

ENTRYPOINT [ "entrypoint.sh" ]