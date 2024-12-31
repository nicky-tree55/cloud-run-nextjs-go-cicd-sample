
ARG IMG_VER="20.18-slim"


### base ####
FROM node:${IMG_VER} AS base
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
    libvips42 \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g npm@latest
RUN corepack disable

FROM base AS init
WORKDIR /app

FROM base AS dev
WORKDIR /app

FROM base AS builder
WORKDIR /app
ARG NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_API_URL=${NEXT_PUBLIC_API_URL}
COPY ./src/package.json ./src/package-lock.json ./
RUN npm ci
ENV NODE_ENV=production
COPY ./src .
RUN npm run build


FROM gcr.io/distroless/nodejs20-debian12 AS runner
WORKDIR /app

COPY --from=builder --chown=nonroot:nonroot /app/.next/standalone ./
COPY --from=builder --chown=nonroot:nonroot /app/.next/static ./.next/static

USER nonroot

CMD ["server.js"]