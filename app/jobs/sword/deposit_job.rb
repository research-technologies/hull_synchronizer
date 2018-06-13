module Sword
  # SWORD deposit job
  class DepositJob < Gush::Job
    
    # @todo
    # Prepare and perform a single SWORD deposit
    # payloads.first[:output] [Hash] metadata and files location
    def perform
      # payloads.first[:output]
      raise NotImplementedError
    end
  end
end
