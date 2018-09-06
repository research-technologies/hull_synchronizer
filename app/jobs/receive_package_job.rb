# Unpack the DIP to prepare multiple deposits and calm metadata
require 'box/api'

class ReceivePackageJob < Gush::Job
  attr_reader :event_code, :message_text, :processor, :submission_dir,:folder_id

  delegate :package_payload, :works_payload, to: :processor

  # Processes the submission package
  def perform
    # params should contain all of the params pobtained from box.
    # Need folder_id
    @processor = Box::Api.new(params: params)
    @folder_id = params[:item_id]
    @submission_dir = @processor.receive_package
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
      # needs submission_dir
      output(
        event: 'success',
        message: 'Received package',
        source_dir: @submission_dir,
        item_id: @folder_id
      )
    end
end
