#!/bin/bash

apt update

DEBIAN_FRONTEND=noninteractive \
    apt install -y \
    sudo \
    ssh \
    net-tools \
    ethtool \
    ifupdown \
    network-manager \
    iputils-ping \
    git \
    vim \
    redis \
    memcached \
    mysql-server \
    postgresql postgresql-contrib \
    nginx \
    apache2
