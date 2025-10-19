docker run --rm -it \
  -v "$PWD":/workspace \
  -u "$(id -u):$(id -g)" \
  dev-con:latest bash
