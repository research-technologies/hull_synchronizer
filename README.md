# Hull Synchronizer

Hull Synchronizer is a rails application that supports a digital preservation and digital asset management solution by providing an integration and monitoring point between different services.

## Prerequisities

The application needs to communicate with:

* An instance of [Archivematica](https://www.archivematica.org/en/) and the Archivematica Storage Service
* An instance of [Hyrax](https://github.com/samvera/hyrax)
* A [Box](https://www.box.com) application and Box subscription

@todo point to documentation on hull_culture
@todo point to archivematica deployment notes
@todo point to documentation on the autoarchiver in box

The hull_synchronizer application requires:

* Ruby version: tested with Ruby 2.4.* or above
* Redis
* Database (tested with Postgres)
* Sidekiq

## Setup

```
bundle install
rails db:create
rails db:migrate
```

## Environment Variables

The application requires several Environment Variables to be set. These are listed in the file `.rbenv-vars-example`. If using `rbenv`, copy `.rbenv-vars-example` to `.rbenv-vars` in the application root directory and set the values. Otherwise, setup the variables however you would normally do so.

## Testing

The application has a partial test suite using rspec, run:

`rspec`
