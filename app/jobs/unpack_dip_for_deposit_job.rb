# Unpack the DIP to prepare multiple deposits
class UnpackDipForDepositJob < Gush::Job
  # @todo
  # Processes the DIP and builds a hash of info ready for the SWORD deposit job
  # payloads.first[:output] [Hash] metadata for Package and DIP location
  def perform
    # payloads.first[:output]
    raise NotImplementedError
  end
end
