FROM golang:latest AS build

ARG GIT_CI_REF=master

RUN git clone https://github.com/arp242/goatcounter.git
RUN cd goatcounter \
  && git checkout $GIT_CI_REF \
  && go build -ldflags="-X zgo.at/goatcounter/v2.Version=$(git log -n1 --format='%h_%cI')" ./cmd/goatcounter

FROM debian:bookworm-slim

WORKDIR /goatcounter

ENV GOATCOUNTER_LISTEN '0.0.0.0:8080'
ENV GOATCOUNTER_DB 'sqlite:///goatcounter/db/goatcounter.sqlite3'
ENV GOATCOUNTER_SMTP ''

RUN apt-get update \
  && apt-get install -y ca-certificates \
  && update-ca-certificates --fresh

COPY --from=build /go/goatcounter/goatcounter /usr/bin/goatcounter
COPY goatcounter.sh ./
COPY entrypoint.sh /entrypoint.sh

VOLUME ["/goatcounter/db"]
EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/goatcounter/goatcounter.sh"]
