# ==============================================================================
# Remediated & Hardened Node.js Dockerfile (ivolve-app:v2)
# ==============================================================================
# 1. Update from vulnerable Debian Bullseye to minimal Alpine Linux
FROM node:20-alpine

# Set production environment
ENV NODE_ENV=production

WORKDIR /app

# Copy dependency specifications
COPY package.json ./

# Install updated dependencies and clean npm cache to minimize layer size
RUN npm install --omit=dev && npm cache clean --force

# Copy application source code
COPY app.js ./

# Set file permissions for the built-in non-root 'node' user
RUN chown -R node:node /app

# Run as non-root user
USER node

# Expose application port
EXPOSE 3000

# Execute using node directly (avoiding npm wrapper process)
CMD ["node", "app.js"]
