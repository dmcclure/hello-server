FROM golang:1.8

RUN mkdir -p /opt/app
WORKDIR /opt/app

COPY . /opt/app
RUN go build -o main .
EXPOSE 9090
CMD ./main
