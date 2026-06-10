# RADHA backend — production image (NestJS API / worker / scheduler).
#
# This is a pnpm-monorepo build, so the build context MUST be the repo root
# (it needs pnpm-workspace.yaml + packages/shared-types + server). Build with:
#   docker build -t radha-server .
#
# One image, three entrypoints — the compose file overrides the command for the
# worker + scheduler. Postgres/Redis are external (RDS + ElastiCache); nothing
# stateful runs in here.
#
# NOTE on the `@/*` path alias: `nest build` (tsc) does not rewrite the alias in
# `dist/`, so the build runs `tsc-alias -p tsconfig.build.json` after `nest build`
# (see server/package.json "build") to rewrite every `@/x` import into a real
# relative path. The compiled `dist/` therefore needs NO runtime path resolver —
# we run plain `node dist/main.api.js`. (`tsconfig-paths` stays in devDependencies
# because the ts-node DB import CLIs still use `-r tsconfig-paths/register`.)

FROM node:20-bookworm-slim AS build
ENV PNPM_HOME=/pnpm
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate
WORKDIR /app

# Copy the whole (dockerignore-pruned) monorepo and install + build. A single
# stage keeps the build reliable for a pnpm workspace; slim later if needed.
COPY . .
RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile \
 && pnpm --filter @radha/server build

ENV NODE_ENV=production
WORKDIR /app/server

# Drop privileges.
USER node

EXPOSE 3000

# API by default; worker + scheduler override `command:` in docker-compose.prod.
CMD ["node", "dist/main.api.js"]
