FROM node:22-alpine

ENV NODE_ENV=production

WORKDIR /usr/src/app

COPY package.json ./
RUN npm install --omit=dev

COPY app.js .

EXPOSE 8084

CMD ["node", "app.js"]
