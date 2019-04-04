# Hull Synchronizer

[![Build Status](https://travis-ci.org/research-technologies/hull_synchronizer.svg?branch=master)](https://travis-ci.org/research-technologies/hull_synchronizer)
[![Coverage Status](https://coveralls.io/repos/github/research-technologies/hull_synchronizer/badge.svg?branch=master)](https://coveralls.io/github/research-technologies/hull_synchronizer?branch=master)

Hull Synchronizer is a rails application that supports a digital preservation and digital asset management solution by providing an integration and monitoring point between different services.

## Prerequisities

The application needs to communicate with:

* An instance of [Archivematica](https://www.archivematica.org/en/) and the Archivematica Storage Service
* An instance of [Hyrax](https://github.com/samvera/hyrax), setup with the appropriate models. Ideally you shoud use [hull_culture](https://github.com/research-technologies/hull_culture) with [hyrax_leaf](https://github.com/research-technologies/hyrax_leaf)
* A [Box](https://www.box.com) application and Box subscription setup using the following documentation: [Creating a Box Application](https://github.com/research-technologies/hull_synchronizer/wiki/Create-a-Box-application-with-JWT-auth)
* An instance of CALM (via access to the CALM API)

The application shared a storage mount with:

* Archivematica

## Getting started

The hull_synchronizer application requires:

* Ruby version: Ruby 2.4.* or above
* Redis
* Database (tested with Postgres)
* Sidekiq

### Setup

```
bundle install
rails db:create
rails db:migrate
```

# Login

The application is configured with `devise` to require login. There is a rake task available to create the initial user:

```
  rake sync:setup_admin_user[email, password]
```

This user can then be used to create subsequent user accounts by logging in and navigating to the 'Manage Users' tab. Check the 'admin' box to allow the new user add/edit/delete Users.

## Getting Started using docker

Ensure you have docker and docker-compose. See [notes on installing docker](https://github.com/research-technologies/hull_synchronizer/wiki/Notes-on-installing-docker)

To build and run the system in your local environment,

Clone the repository and switch to the feature/docker_setup branch
```
git clone https://github.com/research-technologies/hull_synchronizer.git
git fetch
git checkout feature/docker_setup
```

Issue the docker-compose `up` command:
```bash
$ docker-compose up --build
```
You should see the rails app at localhost:3000 (if you set EXTERNAL_PORT to a different port, it will be running on that port)

## Environment Variables

 * The environment variables used by docker when running the containers and by the rails application should be in file named .env
 * For docker, copy the file .env.template to .env and change / add the necessary information
 * For running the application without docker, setup the ENVIRONMENT VARIABLES as you would normally do so (eg. .rbenv-vars)

### Secrets

Generate a new secret with:

```
rails secret
```

## Testing

The application has a partial test suite using rspec, run:

`rspec`
