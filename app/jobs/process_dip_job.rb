# Unpack the DIP to prepare multiple deposits and calm metadata
class ProcessDIPJob < Gush::Job
  require 'dip_processor'
  
  attr_reader :event_code, :processor, :message_text
  
  delegate :package_payload, :works_payload, to: :processor

  # Processes the DIP, creates and writes the Zipped Bagit for deposit.
  # Builds a hash of info ready for the SWORD and CALM deposit jobs.
  def perform
    @processor = DIPProcessor.new(params: payloads.first[:output])
    processor.process
    build_output
  rescue StandardError => e
    processor.cleanup unless processor.blank?
    output(
        event: 'failed',
        message: e.message,
        package: payloads.first[:output][:package],
        works: payloads.first[:output][:works]
        )
    fail!
  end

  private

    def build_output
      output(
        event: 'success',
        message: message_text,
        package: package_payload,
        works: works_payload
      )
    end
end
