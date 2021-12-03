#!/bin/bash

red="\033[0;31m"
green="\033[0;32m"
normal="\033[0m"
bold="\033[1m"

print_ok="[${green}OK${normal}]"
print_fail="[${red}FAIL${normal}]"

echo "Creating pids folders"
mkdir -p $PIDS_PATH

if [ ! -d $LOGS_PATH ]; then
  # Persist some logs (assuming that LOGS_PATH is somewhere on a PV)
  mkdir -p $LOGS_PATH/apache2
  mkdir -p $LOGS_PATH/hullsync
  mkdir -p /etc/cron.daily
  # trim_weblogs will trim away logs older than 21 days
  mv /var/tmp/trim_weblogs /etc/cron.daily/trim_weblogs
fi

##########
# apache #
##########

#put server name in apache conf
sed -i "s/#HULLSYNC_SERVER_NAME#/$HULLSYNC_SERVER_NAME/" /etc/apache2/sites-available/hullsync.conf
sed -i "s/#HULLSYNC_SERVER_NAME#/$HULLSYNC_SERVER_NAME/" /etc/apache2/sites-available/hullsync_ssl.conf

# For now $USE_SS_CERT will control whether or not to use a self-signed certificate or get one from letsencrypt
# letsenrypt won't work with IPs, or with domainnames without dots in then (eg localhost) or from behind a firewall even if we give the NSG the acme :@ (!!)
if [ $USE_SS_CERT ]; then
  echo -e "-- ${bold}Making self-signed certificates for local container ($HULLSYNC_SERVER_NAME)${normal} --"
  /bin/gen_cert.sh $HULLSYNC_SERVER_NAME
  if [ -f /etc/ssl/certs/$HULLSYNC_SERVER_NAME.crt ]; then
    printf "%-50s $print_ok\n" "Certificates generated"
  else
    printf "%-50s $print_fail\n" "Certificates Could not be generated ($?)"
  fi
else
  echo -e "-- ${bold}Obtaining certificates from letsencrypt using certbot ($HULLSYNC_SERVER_NAME)${normal} --"
  service apache2 start

  staging=""
  ## Maybe we want staging certs for dev instances? but they will use a FAKE CA and not really allow us to test stuff properly
  ## Perhaps when letsencrypt start issuing certs for IPs we should modify the above so that --staging is used with certbot when HOSTNAME_IS_IP?
  [[ $ENVIRONMENT == "dev" ]] && staging="--staging"

  mkdir -p /var/www/acme-docroot

  # Correct cert on data volume in /data/pki/certs? We should be able to just bring apache up with ssl
  # If not...
  if [ ! -f /etc/ssl/certs/$HULLSYNC_SERVER_NAME.crt ]; then
    # Lets encrypt has a cert but for some reason this has not been copied to where apache wants them
    if [ -f /etc/letsencrypt/live/$HULLSYNC_SERVER_NAME/fullchain.pem ]; then
      echo -e "Linking existing cert/key to /etc/ssl" 
      ln -s /etc/letsencrypt/live/$HULLSYNC_SERVER_NAME/fullchain.pem /etc/ssl/certs/$HULLSYNC_SERVER_NAME.crt
      ln -s /etc/letsencrypt/live/$HULLSYNC_SERVER_NAME/privkey.pem /etc/ssl/private/$HULLSYNC_SERVER_NAME.key
    else
      # No cert here, We'll register and get one and store all the gubbins on the letsecnrypt volume (n.b. this needs to be an azuredisk for symlink reasons)
      echo -e "Getting new cert and linking cert/key to /etc/ssl"
      mkdir -p /var/www/acme-docroot/.well-known/acme-challenge
      certbot -n certonly --webroot $staging -w /var/www/acme-docroot/ --expand --agree-tos --email $ADMIN_EMAIL --cert-name $HULLSYNC_SERVER_NAME -d $HULLSYNC_SERVER_NAME
     # In case these are somehow hanging around to wreck the symlinking
      [ -f  /etc/ssl/certs/$HULLSYNC_SERVER_NAME.crt ] && rm /etc/ssl/certs/$HULLSYNC_SERVER_NAME.crt
      [ -f  /etc/ssl/private/$HULLSYNC_SERVER_NAME.key ] && rm /etc/ssl/private/$HULLSYNC_SERVER_NAME.key

      # Link cert and key to a location that our general apache config will know about
      if [ -f /etc/letsencrypt/live/$HULLSYNC_SERVER_NAME/fullchain.pem ]; then
        ln -s /etc/letsencrypt/live/$HULLSYNC_SERVER_NAME/fullchain.pem /etc/ssl/certs/$HULLSYNC_SERVER_NAME.crt
        ln -s /etc/letsencrypt/live/$HULLSYNC_SERVER_NAME/privkey.pem /etc/ssl/private/$HULLSYNC_SERVER_NAME.key
      else
        echo -e "${red}${bold}Certificate could not be obtained from letsencrypt using certbot!${normal}"
      fi

      # Certbot starts apache as a service.... we have no need for this once the certificate is generated so let's stop it
      service apache2 stop
    fi
    printf "%-50s $print_ok\n" "Certificate obtained"; # hmmm... catch an error maybe?
  else
     printf "%-50s $print_ok\n" "Certificate already in place";
  fi
  echo -e "-- ${bold}Setting up auto renewal${normal} --"
  # Remove this one as it is no good to us in this context
  rm /etc/cron.d/certbot
  # Add some evaluated variables 
  sed -i "s/#HULLSYNC_SERVER_NAME#/$HULLSYNC_SERVER_NAME/g" /var/tmp/renew_cert
  sed -i "s/#ADMIN_EMAIL#/$ADMIN_EMAIL/g" /var/tmp/renew_cert
  # copy renew_script into cron.monthly (whould be frequent enough)
  mkdir -p /etc/cron.monthly
  mv /var/tmp/renew_cert /etc/cron.monthly/renew_cert
  service cron start
  printf "%-50s $print_ok\n" "renew_cert script moved to /etc/cron.monthly";
fi

echo "--------- Restarting Apache with ssl ---------"
a2ensite hullsync_ssl
service apache2 reload
service apache2 restart

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
#bundle exec rake db:create # @todo shouldn't run this each time
bundle exec rake db:migrate

# setup the admin user
bundle exec rake sync:setup_admin_user[$( echo $ADMIN_USER),$( echo $ADMIN_PASSWORD)]

echo "--------- Starting Hull synchronizer in $RAILS_ENV mode ---------"
rm -f /tmp/"$APP_KEY".pid
#bundle exec rails server -p "$RAILS_PORT" -b '0.0.0.0' --pid /tmp/"$APP_KEY".pid

RAILS_START=`bundle exec rails server -p $RAILS_PORT -b '0.0.0.0' --pid /tmp/$APP_KEY.pid`
if [ "$?" -ne "0" ]; then
  echo "### There was an issue starting rails/puma. We have kept this container alive for you to go and see what's up ###"
  tail -f /dev/null
fi
tail -f /dev/null

