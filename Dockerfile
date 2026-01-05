FROM node:20-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci --omit=dev

FROM node:20-alpine AS runtime
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000

RUN addgroup -S -g 10001 app && adduser -S -u 10001 -G app app

COPY --from=deps /app/node_modules ./node_modules
COPY package.json ./package.json
COPY src ./src

USER app
EXPOSE 3000
CMD ["node", "src/server.js"]
