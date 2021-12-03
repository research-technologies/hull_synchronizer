# RM: This is here just to stop errors that occur because we are recieving job 
# requests (IngestJob and CreateDerivativesJob) from hyrax to the hullsyncsidekiq 
# for some reason. This will stop name errors and hopefully not mess up the post 
# ingest processing in hyrax which will be handled by the sidekiq pod

class CreateDerivativesJob < ActiveJob::Base
  queue_as :default
  
  def perform(*args)
  end
  
end
