FROM alpine:3.20
RUN apk add --no-cache ca-certificates curl unzip nginx && \
    XRAY_VER=v1.8.24 && \
    case "$(uname -m)" in \
      aarch64|arm64) ASSET="Xray-linux-arm64-v8a.zip" ;; \
      x86_64|amd64)  ASSET="Xray-linux-64.zip" ;; \
      *) echo "unsupported arch $(uname -m)" >&2; exit 1 ;; \
    esac && \
    curl -fsSL -o /tmp/xray.zip "https://github.com/XTLS/Xray-core/releases/download/${XRAY_VER}/${ASSET}" && \
    mkdir -p /usr/local/bin/xray && unzip -o /tmp/xray.zip -d /usr/local/bin/xray && \
    chmod +x /usr/local/bin/xray/xray && rm /tmp/xray.zip && \
    mkdir -p /run/nginx
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENV PORT=8080
EXPOSE 8080
CMD ["/entrypoint.sh"]
