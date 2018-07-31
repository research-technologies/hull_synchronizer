# Unpack the DIP to prepare multiple deposits and calm metadata
class ProcessDIPJob < Gush::Job
  require 'dip_processor'
  require 'dip_reader'
  require 'willow_sword'
  
  attr_reader :event_code, :processor, :message_text
  
  delegate :package_payload, :works_payload, to: :processor

  # Processes the DIP, creates and writes the Zipped Bagit for deposit.
  # Builds a hash of info ready for the SWORD and CALM deposit jobs.
  def perform
    @processor = DIPProcessor.new(params: payloads.first[:output])
    processor.process
    build_output
  rescue StandardError => e
    @message_text = e.message
    @event_code = 'failed'
    processor.cleanup
    build_output
    fail!
  end

  private

    def event
      event_code.blank? ? 'success' : event_code
    end

    def build_output
      output(
        event: event,
        message: message_text,
        package: package_payload,
        works: works_payload
      )
    end
end
