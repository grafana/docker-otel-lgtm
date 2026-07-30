FROM node:24-alpine@sha256:f70403e87646dc51b45295f4b8b70cdad0b63d2297c4c9899119b03f7af7a6b3

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY .npmrc ./
COPY package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node app.js .

USER node

EXPOSE 8084

CMD ["node", "app.js"]
