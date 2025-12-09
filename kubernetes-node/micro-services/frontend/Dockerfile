FROM node:20-alpine

WORKDIR /app

# Dépendances
COPY package*.json ./
RUN npm install
RUN npm ci --only=production

# Code application
COPY . .

# Utilisateur non-root
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001 && \
    chown -R nodejs:nodejs /app

USER nodejs

EXPOSE 3000

CMD ["node", "server.js"]