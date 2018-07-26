module Calm
  # CALM Create / Update job
  class CreateUpdateJob < Gush::Job
    # @todo
    # Create or update CALM records
    # payloads.first[:output] [Hash] metadata and record id
    def perform
      # payloads.first[:output]
      raise NotImplementedError
    end
  end
end
