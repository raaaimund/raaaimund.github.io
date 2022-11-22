FROM ruby:2.6.3-alpine3.9 AS builder
RUN apk add --no-cache build-base libffi-dev
RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
RUN gem install bundler
RUN bundle install

FROM jekyll/jekyll:4.2.2
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . .
CMD [ "jekyll", "serve", "--incremental", "--livereload", "--force_polling" ]