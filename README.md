# `simple_passenger` Chef cookbook

[![Chef cookbook](https://img.shields.io/cookbook/v/simple_passenger.svg?maxAge=3600)](https://supermarket.chef.io/cookbooks/simple_passenger) [![Travis](https://img.shields.io/travis/atheiman/simple-passenger-cookbook.svg?maxAge=3600)](https://travis-ci.org/atheiman/simple-passenger-cookbook)

Chef cookbook to deploy a [Rack based Ruby web application](http://rack.github.io/) (Rails, Sinatra, etc) with
[Passenger standalone](https://www.phusionpassenger.com/library/config/standalone/).

# Usage

Pretty straightforward, this cookbook only has one required attribute. Specify
`['passenger']['git_repo']` pointing to your git repository (with the `.git` on the end) and call
the default recipe to run your app with passenger standalone.

This cookbook also creates a `Passengerfile.json` using the attributes under
`['passenger']['passengerfile']`. Refer to the
[`Passengerfile.json` reference](https://www.phusionpassenger.com/library/config/standalone/reference/)
and the [attributes](./attributes/) directory for help with these attributes.

# Testing

Unit tests are run on all pushes to GitHub by [Travis CI](https://travis-ci.org/atheiman/simple-passenger-cookbook).

```shell
# install gem dependencies
bundle
# unit tests
bundle exec rspec
# integration tests
bundle exec kitchen test
```

# Contributing

Enhancements and bug fixes are appreciated! Remember, this cookbook is designed to be very simple.

1. Fork the repo
1. Create a feature or fix branch with an intuitive name (`fix/some-bug`, `feat/some-feature`)
1. Add relevant tests (kitchen, chefspec, etc)
1. Create a pull request back to this repo

# Chef Supermarket

This cookbook is available in [the community Chef Supermarket](https://supermarket.chef.io/cookbooks/simple_passenger). To push new versions:

```shell
bundle install --binstubs
# make changes
# update metadata version
git commit -am 'some fixes'
git push
# tag and push to supermarket
bin/stove
```
