FROM node:24-alpine@sha256:5fa278c599dbba0c8f873d8717d50ecbb57c5ae6a53b7ab240c25135e0b65995

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY .npmrc ./
COPY package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node app.js .

USER node

EXPOSE 8084

CMD ["node", "app.js"]
