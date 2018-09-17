# Unpack the DIP to prepare multiple deposits and calm metadata
require 'box/api'

class InformUserJob < Gush::Job
  attr_reader :event_code, :processor, :number_of_works, :path

  delegate :package_payload, :works_payload, to: :processor

  # Processes the submission package
  def perform
    # payload contains message_text, path, number_of_works, status, item_id
    @params = payloads.first[:output]
    @path = params[:path]
    @number_of_works = params[:number_of_works]
    @processor = Box::Api.new(@params)
    @processor.inform_user
    build_output
  # Need to decide when to retry. See ingest_status as example
  rescue StandardError => e
    # processor.cleanup unless processor.blank?
    output(
        event: 'failed',
        message: e.message
        )
    fail!
  end

  private

    def build_output
      output(
        event: 'success',
        message: 'Informed user the status of checks for submission',
        path: @path,
        number_of_works: @number_of_works
      )
    end
end
