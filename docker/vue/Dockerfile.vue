FROM node:20-alpine AS base

WORKDIR /var/www

COPY ./frontend .

RUN npm install

FROM base AS dev

CMD ["npm", "run", "dev"]

FROM base AS build

RUN npm run build

FROM nginx:1.27.2-alpine AS prod

COPY --from=build /var/www/dist /usr/share/nginx/html
COPY ./docker/vue/config/nginx-vue.conf /etc/nginx/nginx.conf

EXPOSE 80 443

CMD ["nginx", "-g", "daemon off;"]
