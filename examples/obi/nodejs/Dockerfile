FROM node:22-alpine

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node app.js .

USER node

EXPOSE 8084

CMD ["node", "app.js"]
