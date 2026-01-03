# syntax=docker/dockerfile:1

FROM node:20-alpine AS deps
WORKDIR /app

# Install only production dependencies (reproducible via lockfile)
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:20-alpine AS runtime
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

# Create an unprivileged user with a fixed UID/GID (easy to enforce in Kubernetes)
RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./package.json
COPY src ./src

USER app
EXPOSE 3000
CMD ["node", "src/server.js"]
