FROM node:latest

MAINTAINER Tobias Gerschner <tobias.gerschner@gmail.com>

RUN apt-get update && \
    apt-get -y install inotify-tools && \
    apt-get clean && \
    apt-get autoclean

WORKDIR /opt/app
USER node
