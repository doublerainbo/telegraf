FROM golang:1.10.3 as builder

RUN chmod -R 755 "$GOPATH"

RUN DEBIAN_FRONTEND=noninteractive \
	apt update && apt install -y --no-install-recommends \
	autoconf \
	git \
	libtool \
	locales \
	make \
	python-boto \
	rpm \
	ruby \
	ruby-dev \
	zip && \
	rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/share/zoneinfo/Etc/UTC /etc/localtime
RUN locale-gen C.UTF-8 || true
ENV LANG=C.UTF-8

RUN gem install fpm

RUN go get -d github.com/golang/dep && \
    cd src/github.com/golang/dep && \
    git checkout -q v0.5.0 && \
    go install -ldflags="-X main.version=v0.5.0" ./cmd/dep

WORKDIR "$GOPATH"/src/github.com/influxdata/telegraf
COPY . ./

RUN ./scripts/build.py --package --platform=linux --arch=amd64

# ---------------------------------------
FROM ubuntu:bionic
COPY --from=builder /go/src/github.com/influxdata/telegraf/build/telegraf /usr/bin/telegraf

EXPOSE 8125/udp 8092/udp 8094

CMD ["telegraf"]
