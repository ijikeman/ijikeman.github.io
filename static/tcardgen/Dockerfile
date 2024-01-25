FROM golang:latest

RUN go install github.com/Ladicle/tcardgen@latest

# Install ImageMagick
RUN apt-get update
RUN apt-get install imagemagick -y
