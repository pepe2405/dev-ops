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

# Create an unprivileged user (matches k8s runAsNonRoot)
RUN addgroup -S app && adduser -S app -G app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./package.json
COPY src ./src

USER app
EXPOSE 3000
CMD ["node", "src/server.js"]
