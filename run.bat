docker build --tag blog .
docker rm -f blog
docker run --name blog -p 4000:4000 blog