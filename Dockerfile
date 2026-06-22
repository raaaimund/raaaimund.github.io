FROM ruby:3.3-alpine
RUN apk add --no-cache build-base libffi-dev libxml2-dev libxslt-dev git
WORKDIR /srv/jekyll
COPY Gemfile /srv/jekyll/Gemfile
RUN gem install bundler && bundle install
COPY . .
CMD ["jekyll", "serve", "--incremental", "--livereload", "--force_polling", "--host", "0.0.0.0"]