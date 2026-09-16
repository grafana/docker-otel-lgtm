FROM node:24-alpine@sha256:50c8e8ca1d27439048670df5883f32d57cf81cff6233222c893fd0d9884cbd81

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
