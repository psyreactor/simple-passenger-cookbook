set -ev

case $SUITE in
other)
  foodcritic --context --progress .
  rubocop --lint --display-style-guide --extra-details --display-cop-names
  rspec
  ;;
*)
  rake integration:docker[test,"$SUITE",2]
  ;;
esac
