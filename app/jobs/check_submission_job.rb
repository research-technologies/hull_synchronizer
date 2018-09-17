# Unpack the DIP to prepare multiple deposits and calm metadata
require 'submission_checker'

class CheckSubmissionJob < Gush::Job
  attr_reader :event_code, :processor, :number_of_works

  delegate :package_payload, :works_payload, to: :processor

  # Processes the submission package
  def perform
    # params contain source_dir and item_id
    # @params = payloads.first[:output]
    @params = params
    @processor = SubmissionChecker.new(params: @params)
    @processor.check_submission
    @message_text = @processor.errors
    @number_of_works = @processor.row_count
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
      if @processor.status == true
        msg = 'Checked submission package. It is ready to be processed'
      else
        msg = 'Checked submission package. It has errors'
      end
      output(
        event: 'success',
        message: msg,
        message_text: @processor.errors,
        path: params[:source_dir],
        number_of_works: @number_of_works,
        status: @processor.status,
        item_id: @params[:item_id]
      )
    end
end
