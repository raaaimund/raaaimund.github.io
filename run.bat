docker rm -f blog
docker build --tag blog .
docker run --name blog -p 4000:4000 blog