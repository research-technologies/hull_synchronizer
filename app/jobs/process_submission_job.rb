# Unpack the DIP to prepare multiple deposits and calm metadata
class ProcessSubmissionJob < Gush::Job
  require 'submission_processor'

  attr_reader :processor

  # Processes the submission package
  def perform
    @processor = SubmissionProcessor.new(params: params)
    processor.process_submission
    build_output
  # Need to decide when to retry. See ingest_status as example
  rescue StandardError => e
    # processor.cleanup unless processor.blank?
    output(
        event: 'failed',
        message: "#{e.message}\n\n#{e.backtrace.join('\n')}"
        )
    fail!
  end

  private

    def build_output
      output(
        event: 'success',
        message: 'Processed submission package and built bag',
        path: processor.current_transfer_dir,
        accession: processor.accession
      )
    end
end
