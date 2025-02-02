FROM ruby:3.3.2

LABEL maintainer="thiago.pelizoni@gmail.com"

ENV NODE_VERSION=18.x
ENV YARN_VERSION=1.22.19

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  curl \
  gnupg2

RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION | bash - && apt-get install -y nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update && apt-get install -y yarn=$YARN_VERSION-1

RUN wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | apt-key add -
RUN echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list
RUN apt-get update && apt-get install -y mongodb-mongosh

WORKDIR /api

ADD ./api .

RUN gem install bundler && bundle install

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]