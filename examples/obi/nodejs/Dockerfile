FROM node:24-alpine@sha256:156b55f92e98ccd5ef49578a8cea0df4679826564bad1c9d4ef04462b9f0ded6

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY .npmrc ./
COPY package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node app.js .

USER node

EXPOSE 8084

CMD ["node", "app.js"]
