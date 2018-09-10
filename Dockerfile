FROM golang:1.8

# These build arguments are passed in via the "docker build" command done by CodeBuild (in buildspec.yml).
# We copy them to environment variables so they can be accessed from our app.
ARG IMAGE_TAG
ARG BUILD_DATE
ENV IMAGE_TAG ${IMAGE_TAG}
ENV BUILD_DATE ${BUILD_DATE}

RUN mkdir -p /opt/app
WORKDIR /opt/app

COPY . /opt/app
RUN go build -o main .
EXPOSE 9090
CMD ./main
