class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  require 'archivematica/api'
  require 'sword/api'
end
