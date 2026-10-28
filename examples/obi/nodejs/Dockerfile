FROM node:26-alpine@sha256:40cd011b55415bc894e45b02fdd5a5dfde056921b7d23a64c74f80497af48797

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY .npmrc ./
COPY package*.json ./
RUN npm ci --omit=dev

COPY --chown=node:node app.js .

# Run as the node user
USER 1000

EXPOSE 8084

CMD ["node", "app.js"]
