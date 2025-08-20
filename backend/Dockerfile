# -------- build stage (installs deps and compiles TS) --------
FROM node:20-alpine AS build
WORKDIR /app

# Install exact deps from package*.json
COPY package*.json ./
RUN npm ci

# Compile TypeScript -> dist/
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# -------- runtime stage (minimal image to run the app) --------
FROM node:20-alpine
WORKDIR /app
ENV NODE_ENV=production

# Only prod deps go into the final image
COPY package*.json ./
RUN npm ci --omit=dev

# Bring compiled JS from the build stage
COPY --from=build /app/dist ./dist

# API listens on 3000 (informational; Compose/ALB will map it)
EXPOSE 3000

# Start the server
CMD ["node", "dist/main.js"]
