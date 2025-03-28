FROM ruby:3.3.2

LABEL maintainer="thiago.pelizoni@gmail.com"

ENV NODE_VERSION=18.x \
    YARN_VERSION=1.22.19 \
    APP_HOME=/api

RUN apt-get update -qq && apt-get install -y --no-install-recommends \
  build-essential \
  libpq-dev \
  curl \
  gnupg2 \
  ffmpeg \
  libavcodec-dev \
  libavformat-dev \
  libavdevice-dev \
  libavfilter-dev \
  libswscale-dev \
  libswresample-dev \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sL https://deb.nodesource.com/setup_$NODE_VERSION | bash - \
  && apt-get install -y --no-install-recommends nodejs \
  && rm -rf /var/lib/apt/lists/*

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update && apt-get install -y --no-install-recommends yarn=$YARN_VERSION-1 \
  && rm -rf /var/lib/apt/lists/*

RUN wget -qO - https://www.mongodb.org/static/pgp/server-5.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodbkey.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/mongodbkey.gpg arch=amd64,arm64] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/5.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-5.0.list \
  && apt-get update && apt-get install -y --no-install-recommends mongodb-mongosh \
  && rm -rf /var/lib/apt/lists/*

WORKDIR $APP_HOME

ADD ./api .

RUN gem install bundler && bundle install --jobs 4 --retry 3

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
