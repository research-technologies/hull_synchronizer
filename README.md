# Hull Synchronizer

[![Build Status](https://travis-ci.org/research-technologies/hull_synchronizer.svg?branch=master)](https://travis-ci.org/research-technologies/hull_synchronizer)
[![Coverage Status](https://coveralls.io/repos/github/research-technologies/hull_synchronizer/badge.svg?branch=master)](https://coveralls.io/github/research-technologies/hull_synchronizer?branch=master)

Hull Synchronizer is a rails application that supports a digital preservation and digital asset management solution by providing an integration and monitoring point between different services.

## Prerequisities

The application needs to communicate with:

* An instance of [Archivematica](https://www.archivematica.org/en/) and the Archivematica Storage Service
* An instance of [Hyrax](https://github.com/samvera/hyrax)
* A [Box](https://www.box.com) application and Box subscription

@todo point to documentation on hull_culture
@todo point to archivematica deployment notes
@todo point to documentation on the autoarchiver in box

## Getting started

The hull_synchronizer application requires:

* Ruby version: tested with Ruby 2.4.* or above
* Redis
* Database (tested with Postgres)
* Sidekiq

### Setup

```
bundle install
rails db:create
rails db:migrate
```

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

The application requires several Environment Variables to be set. These are listed in the file `.rbenv-vars-example`. If using `rbenv` or using the docker setup, copy `.rbenv-vars-example` to `.rbenv-vars` in the application root directory and set the values. Otherwise, setup the environment variables however you would normally do so.

## Testing

The application has a partial test suite using rspec, run:

`rspec`
