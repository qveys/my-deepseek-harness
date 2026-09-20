# syntax=docker/dockerfile:1
# Runs dsh from this checkout through the documented source setup: pnpm install,
# pnpm run build, then the built `dsh` launcher.
FROM node:24-bookworm-slim

# build-essential and python3 compile node-pty during install and the flock
# addon during build:native-system; git backs the harness's repository tools.
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      git \
      python3 \
  && rm -rf /var/lib/apt/lists/*

ENV COREPACK_ENABLE_DOWNLOAD_PROMPT=0
RUN corepack enable

# /app is owned by node because pnpm writes temporary files directly into the
# workspace root. The other two exist before the mounts land so a volume
# inherits the node user instead of root: $DSH_HOME holds profiles and Session
# data, /workspace is where the agent works.
RUN mkdir -p /app /home/node/.dsh /workspace \
  && chown node:node /app /home/node/.dsh /workspace
ENV DSH_HOME=/home/node/.dsh

WORKDIR /app
COPY --chown=node:node . .
USER node
# CI=true skips host Git hook setup. Git metadata stays in the build context
# for client version metadata. Allocate at least 4 GB to the Docker engine.
RUN CI=true pnpm install --frozen-lockfile \
  && pnpm run build

# `dsh` is the only supported launcher (docs/architecture.md#application-launch).
# The built bin resolves from /app regardless of the working directory, so the
# agent's workspace mounts anywhere.
ENTRYPOINT ["node", "/app/apps/cli/lib/bin.js"]
CMD ["--profile", "web", "--no-open"]
