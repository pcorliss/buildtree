#!/bin/bash

set -o nounset
set -o errexit

cd /tmp

export FOO="foo"
export BAR="bar"
export SHA="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
export BRANCH="master"
export REPO="foo/bar"
export DIR="/tmp"

if type apt-get 2>/dev/null; then
  apt-get update -y
  apt-get install -y curl wget
else
  yum install curl wget
fi

some_cmd foo bar buzz
some_other_cmd

if [ -f "/etc/init.d/cassandra" ]; then
  /etc/init.d/cassandra start
else
  systemctl start cassandra
fi

if [ -f "/etc/init.d/docker" ]; then
  /etc/init.d/docker start
else
  systemctl start docker
fi

some_cmd foo bar buzz
some_other_cmd

bundle install
mvn clean dependencies

rake
mvn test

if [ "master" == "$BRANCH" ]; then
  asdf
  bar
fi

if [ "release" == "$BRANCH" ]; then
  fubar
fi
