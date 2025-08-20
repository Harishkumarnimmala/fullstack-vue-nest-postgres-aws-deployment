# -------- build stage: compile Vue app to static files --------
FROM node:20-alpine AS build
WORKDIR /app

# install deps
COPY package*.json ./
RUN npm ci

# build
COPY . .
RUN npm run build

# -------- runtime stage: serve with nginx --------
FROM nginx:1.27-alpine
# copy built files to nginx html directory
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
