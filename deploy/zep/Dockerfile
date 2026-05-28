# deploy/zep/Dockerfile
FROM ghcr.io/getzep/zep:0.27.2
USER root
RUN apt-get update && \
    apt-get install -y curl tzdata && \
    rm -rf /var/lib/apt/lists/*
