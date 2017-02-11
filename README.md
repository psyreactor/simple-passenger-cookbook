# `simple_passenger` Chef Cookbook

[![Chef cookbook](https://img.shields.io/cookbook/v/simple_passenger.svg?maxAge=3600)](https://supermarket.chef.io/cookbooks/simple_passenger) [![Travis](https://img.shields.io/travis/atheiman/simple-passenger-cookbook.svg?maxAge=3600)](https://travis-ci.org/atheiman/simple-passenger-cookbook)

Chef cookbook to deploy [Rack-based Ruby web application(s)](http://rack.github.io/) (Rails, Sinatra, etc) with [Passenger standalone](https://www.phusionpassenger.com/library/config/standalone/).


# Usage

First, include `recipe[simple_passenger::default]` on your node's run list. This will install common dependencies for Rack web apps. See [the default recipe](/recipes/default.rb) for more details.

To deploy your app(s) with this cookbook, you can use the [`simple_passenger_app` LWRP](#simple_passenger_app-lwrp) in another cookbook. You can also define apps in the attribute `['passenger']['apps']` as a hash. The keys of this hash should be the name of the app, and the values should be a hash of properties you want to call on the `simple_passenger_app` LWRP. The default recipe will iterate over this hash and call the LWRP for you with the properties you have defined. You can see an example of this attribute approach in [the ChefSpec attributes](/spec/) or [the Test Kitchen attributes](/.kitchen.yml).


## `simple_passenger_app` LWRP

Below are each of the properties defined on the LWRP, see [the resource definition](/resources/app.rb) for defaults and more details. See [the default recipe in the fixture cookbook](/test/fixtures/cookbooks/lwrp_app/recipes/default.rb) used by Test Kitchen integration tests for an example of using this LWRP.

Property | Ruby class | Examples | Description
-------- | ---------- | -------- | -----------
`app_name` | String | `'my-app'` | Name of app to deploy
`git_repo` | String | `'https://github.com/user/my-app.git'` | The URI for the git repository. See [the Chef `git` resource](https://docs.chef.io/resource_git.html).
`git_revision` | String | `'master'`, `'v1.2.3'` | The URI for the git repository. See [the Chef `git` resource](https://docs.chef.io/resource_git.html).
`ruby_version` | String | `'2.2.6'`, `'jruby-9.1.6.0'` | [`ruby-build` definition](https://github.com/rbenv/ruby-build) to install. See [the `ruby_build_ruby` LWRP](https://github.com/sous-chefs/ruby_build#ruby_build_ruby).
`bundler_version` | String | `'1.13.1'`, `'~> 1.12'` | Version of Bundler to install (should be a RubyGems version specification).
`passengerfile` | Hash | `{ environment: 'development', port: 8080 }` | Properties to specify in [`Passengerfile.json`](https://www.phusionpassenger.com/library/config/standalone/reference/) (will be merged over sensible defaults).
`passengerfile_mode` | [String, Integer] | `'644'` | Permissions to set on `Passengerfile.json`. See [the Chef `file` resource](https://docs.chef.io/resource_file.html).
`log_dir_mode` | [String, Integer] | `'0755'` | Permissions to set on the log directory for the app. See [the Chef `directory` resource](https://docs.chef.io/resource_directory.html).
`logrotate_frequency` | String | `'daily'` | See [the `logrotate_app` LWRP](https://github.com/stevendanna/logrotate#logrotate_app)
`logrotate_rotate` | Integer | `7` | See [the `logrotate_app` LWRP](https://github.com/stevendanna/logrotate#logrotate_app)


## Notes

### Multiple apps

This cookbook support multiple apps just as expected. Simply call the LWRP multiple times (or define multiple apps in the attribute `['passenger']['apps']` as a hash). Be sure to bind each app to a different port.


# Testing

Chefspec unit tests and Test Kitchen integration tests are run on all pushes to GitHub by [Travis CI](https://travis-ci.org/atheiman/simple-passenger-cookbook).

```shell
# install gem dependencies
bundle
# unit tests
bundle exec rspec
# integration tests with kitchen-vagrant
bundle exec kitchen test
```

Test Kitchen integration tests are on Travis CI use Docker via kitchen-docker. If you'd like to use Docker to run Test Kitchen integration tests locally:

```shell
# Ensure docker is running first
# On Mac OS X you may need to have sudo commands available with no password,
# the easiest way to do this is run a command as sudo so the next command won't prompt
# for a password
sudo ls
# Run Test Kitchen integration tests with docker (uses concurrency)
KITCHEN_LOCAL_YAML=.kitchen.docker.yml bundle exec kitchen test
```

> Big thanks to https://github.com/zuazo/kitchen-in-travis for the Travis / Test Kitchen guide


# Contributing

Enhancements and bug fixes are appreciated! Remember, this cookbook is designed to be simple.

1. Fork the repo
1. Create a feature or fix branch with an intuitive name (`fix/some-bug`, `feat/some-feature`)
1. Add relevant tests (kitchen, chefspec, etc)
1. Create a pull request back to this repo


# Chef Supermarket

This cookbook is available in [the community Chef Supermarket](https://supermarket.chef.io/cookbooks/simple_passenger). To push new versions with [`stove`](https://github.com/sethvargo/stove):

```shell
bundle install
# make changes
# update metadata version
git commit -am 'some fixes'
git push
# tag and push to supermarket
stove
```
