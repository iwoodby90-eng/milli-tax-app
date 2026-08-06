FROM node:22.22.3-alpine

ENV CI=false

WORKDIR /app

COPY package.json ./
RUN npm install --no-audit --no-fund

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
