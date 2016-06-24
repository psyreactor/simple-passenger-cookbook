# `simple_passenger` Chef cookbook

Chef cookbook to deploy a rack based Ruby web application with
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
