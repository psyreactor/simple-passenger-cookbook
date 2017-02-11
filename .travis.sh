#!/bin/bash -ex

case $SUITE in
chefspec)
  rspec
  ;;
*)
  KITCHEN_LOCAL_YAML='.kitchen.docker.yml' kitchen test "$SUITE" --concurrency=2 --log-level=debug
  ;;
esac
