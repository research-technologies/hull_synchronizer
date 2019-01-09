FROM ruby:2.6

# Setup build variables
ARG RAILS_ENV=production

ENV RAILS_ENV="$RAILS_ENV" \
    LANG=C.UTF-8 \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre \
    RAILS_LOG_TO_STDOUT=yes_please \
    PATH=/fits/fits-1.0.5/:$PATH \
    BUNDLE_JOBS=2 \
    APP_PRODUCTION=/app/ \
    APP_WORKDIR="/app"

# Add backports to apt-get sources
# Install libraries, dependencies, java and fits

RUN echo 'deb http://deb.debian.org/debian jessie-backports main' > /etc/apt/sources.list.d/jessie-backports.list \
    && apt-get update -qq \
    && apt-get install -y --no-install-recommends \
    libpq-dev \
    libxml2-dev libxslt1-dev \
    nodejs \
    ufraw \
    bzip2 unzip xz-utils

# copy gemfiles to production folder
COPY Gemfile Gemfile.lock $APP_PRODUCTION

# install gems to system - use flags dependent on RAILS_ENV
RUN cd $APP_PRODUCTION && \
    if [ "$RAILS_ENV" = "production" ]; then \
            bundle install --without test:development; \
        else \
            bundle install --without production --no-deployment; \
        fi \
    && mv Gemfile.lock Gemfile.lock.built_by_docker

# copy the application
COPY . $APP_PRODUCTION
COPY docker-entrypoint.sh /bin/docker-entrypoint.sh

# use the just built Gemfile.lock, not the one copied into the container and verify the gems are correctly installed
RUN cd $APP_PRODUCTION \
    && mv Gemfile.lock.built_by_docker Gemfile.lock \
    && bundle check

# generate production assets if production environment
RUN if [ "$RAILS_ENV" = "production" ]; then \
        cd $APP_PRODUCTION \
        && SECRET_KEY_BASE_PRODUCTION=0 bundle exec rake assets:clean assets:precompile; \
    fi

WORKDIR $APP_WORKDIR

ARG SECRET_KEY_BASE="ec6aebaf837655680ac99c7a60a7b4ef61d9bcc320a9d3e78ef989bf309f8c9d63ee51b2997a0c5543fe20df30aa253c5fb19e1f065bfaf2be1224258904d45f"
ENV SECRET_KEY_BASE=$SECRET_KEY_BASE

RUN chmod +x /bin/docker-entrypoint.sh
