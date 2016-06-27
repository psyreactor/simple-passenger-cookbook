#!/bin/bash
set -ev

case $SUITE in
other)
  bundle exec foodcritic --context --progress .
  bundle exec rubocop --lint --display-style-guide --extra-details --display-cop-names
  bundle exec rspec
  ;;
*)
  if [[ "${TRAVIS_PULL_REQUEST}" = "false" ]]; then
    bundle exec rake integration:docker[test,"$SUITE",2]
  fi
  ;;
esac
