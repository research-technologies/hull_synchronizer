#!/bin/bash

echo "Creating log folder"
mkdir -p $APP_WORKDIR/log

if [ "$RAILS_ENV" = "production" ]; then
    # Verify all the production gems are installed
    bundle check
else
    # install any missing development gems (as we can tweak the development container without rebuilding it)
    bundle check || bundle install --without production
fi

## Run any pending migrations
bundle exec rake db:migrate

# setup the admin user
bundle exec rake sync:setup_admin_user[$( echo $ADMIN_USER_EMAIL),$( echo $ADMIN_USER_PASSWORD)]

echo "--------- Starting Hull synchronizer in $RAILS_ENV mode ---------"
rm -f /tmp/"$APP_KEY".pid
bundle exec rails server -p "$RAILS_PORT" --pid /tmp/"$APP_KEY".pid
