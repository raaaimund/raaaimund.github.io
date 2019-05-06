FROM jekyll/jekyll:3.8.5
COPY . .
CMD [ "jekyll", "serve" ]