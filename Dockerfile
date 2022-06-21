FROM golang:alpine as builder

RUN apk add --no-cache make git && \
    wget -O /Country.mmdb https://github.com/Dreamacro/maxmind-geoip/releases/latest/download/Country.mmdb
WORKDIR /clash-src
COPY --from=tonistiigi/xx:golang / /
COPY . /clash-src
RUN go mod download && \
    make docker && \
    mv ./bin/clash-docker /clash

FROM alpine:latest
LABEL org.opencontainers.image.source="https://github.com/Dreamacro/clash"

RUN apk add --no-cache ca-certificates tzdata iptables

COPY --from=builder /Country.mmdb /root/.config/clash/
COPY --from=builder /clash /
COPY iptables.sh /iptables.sh
RUN chmod +x iptables.sh
RUN sh iptables.sh
RUN set -o errexit -o nounset \
    && echo "Adding gradle user and group" \
    && addgroup --system --gid 1000 clash \
    && adduser --system --ingroup clash --uid 1000 --shell /bin/ash clash \
    && mkdir /home/clash/.clash \
    && cp /clash /home/clash/clash \
    && chown -R clash:clash /home/clash \
    \
    && echo "Symlinking root Gradle cache to gradle Gradle cache" \
    && ln -s /home/clash/.clash /root/.clash
ENTRYPOINT ["/home/clash/clash"]
