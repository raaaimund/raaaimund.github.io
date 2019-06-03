FROM ruby:2.6.3-alpine3.9 AS builder
RUN apk add --no-cache build-base libffi-dev
RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
RUN bundle install
RUN ls

FROM jekyll/jekyll:3.8.5
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY . .
RUN ls
CMD [ "jekyll", "serve" ]