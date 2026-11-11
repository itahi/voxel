# Base image with Node.js 22 LTS on modern Debian Bookworm (Stable)
FROM node:22-bookworm-slim

# Install system dependencies (curl for healthchecks, procps for process management, ca-certificates for TLS)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy package manifests and .npmrc first for caching
COPY package*.json ./
COPY .npmrc* ./

# Install all dependencies (npm install will bring pre-compiled ffmpeg-static automatically)
RUN npm install --legacy-peer-deps

# Copy source code
COPY . .

# Build Vite frontend for production into /app/dist
RUN npm run build

# Default environment variables (can be overridden by Render or Railway)
ENV NODE_ENV=production
ENV PORT=3000

# Expose HTTP port
EXPOSE 3000

# Health check to ensure Render marks deployment as live immediately
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://127.0.0.1:${PORT}/health || exit 1

# Start the server
CMD ["node", "server.ts"]
