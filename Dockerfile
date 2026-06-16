# RADHA backend — production image (NestJS API / worker / scheduler).
#
# The backend lives in radha_backend/ — standalone pnpm project (not a monorepo).
# Build context is the repo root so `docker compose` can reference it simply.
# Build: docker build -t radha-server .
#
# One image, three entrypoints — the compose file overrides CMD per service.
#
# Path alias: `nest build && tsc-alias` rewrites every @/ import in dist/ to
# a real relative path so no runtime tsconfig-paths is needed.

FROM node:20-bookworm-slim AS build
ENV PNPM_HOME=/pnpm
ENV PATH="$PNPM_HOME:$PATH"
RUN corepack enable && corepack prepare pnpm@8.15.0 --activate

WORKDIR /app

# Copy only the backend dir (mobile / dashboard are not needed in this image).
COPY radha_backend/ .

RUN --mount=type=cache,id=pnpm,target=/pnpm/store \
    pnpm install --frozen-lockfile \
 && pnpm build

ENV NODE_ENV=production

# Drop privileges.
USER node

EXPOSE 3000

# API by default; docker-compose.selfhosted.yml overrides command for worker/scheduler.
CMD ["node", "dist/main.api"]
