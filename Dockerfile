FROM arm32v7/nginx:1.21-alpine as builder

ARG DOCKER_GEN_VERSION

RUN apk add wget

RUN wget "github.com/jwilder/docker-gen/releases/download/$DOCKER_GEN_VERSION/docker-gen-alpine-linux-armhf-$DOCKER_GEN_VERSION.tar.gz"
RUN tar -C /usr/local/bin -xvzf docker-gen-alpine-linux-armhf-$DOCKER_GEN_VERSION.tar.gz


FROM arm32v7/nginx:1.21-alpine

COPY --from=builder /usr/local/bin/docker-gen /usr/local/bin/docker-gen
COPY ./app /app
#ensure docker-entrypoint is executable
RUN chmod +x /app/docker-entrypoint.sh 
COPY ./static/ /usr/share/nginx/html/
WORKDIR /app/

EXPOSE 80
HEALTHCHECK --interval=60s --timeout=10s --start-period=5s --retries=3 CMD curl -f http://localhost/ || exit 1
ENTRYPOINT ["/app/docker-entrypoint.sh"]
