FROM node:18 AS base

# set work directory
WORKDIR /app

# install dependencies
COPY package*.json .
RUN npm i

# copy source
COPY . .

# expose port
EXPOSE 4200

# run app
ENTRYPOINT [ "npm", "start" ]