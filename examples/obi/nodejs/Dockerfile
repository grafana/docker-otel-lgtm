FROM node:24-alpine@sha256:f1f2c6ee5140c8a7e94d379a40a9467395be641716126f65aea28aff35dbb196

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY .npmrc ./
COPY package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node app.js .

USER node

EXPOSE 8084

CMD ["node", "app.js"]
