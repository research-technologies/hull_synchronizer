# Hull Synchronizer

[![Build Status](https://travis-ci.org/research-technologies/hull_synchronizer.svg?branch=master)](https://travis-ci.org/research-technologies/hull_synchronizer)
[![Coverage Status](https://coveralls.io/repos/github/research-technologies/hull_synchronizer/badge.svg?branch=master)](https://coveralls.io/github/research-technologies/hull_synchronizer?branch=master)

Hull Synchronizer is a rails application that supports a digital preservation and digital asset management solution by providing an integration and monitoring point between different services.

## Prerequisities

The application needs to communicate with:

* An instance of [Archivematica](https://www.archivematica.org/en/) and the Archivematica Storage Service
* An instance of [Hyrax](https://github.com/samvera/hyrax), setup with the appropriate models. Ideally you shoud use [hull_culture](https://github.com/research-technologies/hull_culture) with [hyrax_leaf](https://github.com/research-technologies/hyrax_leaf)
* A [Box](https://www.box.com) application and Box subscription setup using the following documentation: [Creating a Box Application](https://github.com/research-technologies/hull_synchronizer/wiki/Create-a-Box-application-with-JWT-auth)

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
You should see the Synchronizer app at localhost:3000

## Environment Variables

The application requires several Environment Variables to be set. These are listed in the file `.env.template`. If using `rbenv` or using the docker setup, copy `.env.template` to `.rbenv-vars` in the application root directory and set the values. Otherwise, setup the environment variables however you would normally do so.

## Testing

The application has a partial test suite using rspec, run:

`rspec`
