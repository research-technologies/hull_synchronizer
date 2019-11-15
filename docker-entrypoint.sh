#!/bin/bash

echo "Creating log folder"
mkdir -p $APP_WORKDIR/log
echo "Creating share folders"
mkdir -p $LOCAL_BOX_DIR $LOCAL_EFS_DATA_DIR $LOCAL_EFS_TRANSFER_DIR /data/dipstore

###########
# certbot #
###########

echo "------------- installing certbot -----------"

add-apt-repository ppa:certbot/certbot -y
apt-get update
apt-get install python-certbot-apache -y --no-install-recommends

echo "-------------- setting up certbot and getting cert(s) -----------"

#Copy in certbot config
cp $APP_WORKDIR/docker/cli.ini /etc/letsencrypt/cli.ini
#make dir that will be used for challenges (if you must change this look at hullsync.conf too)
mkdir -p /var/www/acme-docroot/.well-known/acme-challenge

# We'll register each time as certs are not stored on a persistent volume
certbot register
certbot certonly -n --cert-name base -d $SERVER_NAME

# copy autorenewal script. Dest directory only exists after the first cert is in place
cp $APP_WORKDIR/docker/00_apache2 /etc/letsencrypt/renewal-hooks/deploy/

##########
# apache #
##########

#put server name in apache conf
sed -i "s/#SERVER_NAME#/$SERVER_NAME/" /etc/apache2/sites-available/hullsync.conf

echo "--------- Starting Apache -----------"
service apache2 start

#########
# Rails #
#########

if [ "$RAILS_ENV" = "production" ]; then
    # Verify all the production gems are installed
    bundle check
else
    # install any missing development gems (as we can tweak the development container without rebuilding it)
    bundle check || bundle install --without production
fi

echo "--------------- running migrations -----------"
## Run any pending migrations
bundle exec rake db:create # @todo shouldn't run this each time
bundle exec rake db:migrate

# setup the admin user
bundle exec rake sync:setup_admin_user[$( echo $ADMIN_USER_EMAIL),$( echo $ADMIN_USER_PASSWORD)]

echo "--------- Starting Hull synchronizer in $RAILS_ENV mode ---------"
rm -f $APP_WORKDIR/shared/"$APP_KEY".pid
bundle exec rails server -p "$RAILS_PORT" --pid $APP_WORKDIR/shared/"$APP_KEY".pid
