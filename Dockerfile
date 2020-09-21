FROM debian:buster-slim
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
            netbase wget ca-certificates gnupg \
            build-essential iverilog

WORKDIR /tmp

RUN wget https://paul.bone.id.au/paul.asc && \
            apt-key add paul.asc && \
            echo "deb http://dl.mercurylang.org/deb/ buster main" > /etc/apt/sources.list.d/mercury.list && \
            echo "deb-src http://dl.mercurylang.org/deb/ buster main" >> /etc/apt/sources.list.d/mercury.list && \
            apt-get update && apt-get install -y mercury-recommended

WORKDIR /openvga

COPY .. /openvga


ENV LANG en_US.UTF-8 
