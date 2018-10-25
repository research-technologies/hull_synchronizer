# Check the submited directory and report back to user before processing
require 'submission_checker'

class ReviewSubmissionJob < Gush::Job
  attr_reader :number_of_works, :processor, :params

  # Processes the submission package
  def perform
    # params contain item_name, item_id, item_list and source_dir
    # @params = payloads.first[:output]
    @params = params
    @processor = SubmissionChecker.new(params: params)
    @processor.check_submission
    @message_text = @processor.errors
    @number_of_works = @processor.row_count
    build_output
    fail! if @processor.status == false
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
        msg = 'Successfully reviewed submission package. It is ready to be processed'
        event = 'success'
      else
        msg = 'Submission package has errors'
        event = 'failed'
      end
      inform_user
      output(
        event: event,
        message: msg,
        message_text: @processor.errors,
        source_dir: params[:source_dir],
        number_of_works: @number_of_works,
        status: @processor.status,
        item_id: params[:item_id],
        item_name: params[:item_name],
      )
    end

    def inform_user
      # params need to cointain item_id, item_name, status, message, unlink
      u_params = {
        item_id: params[:item_id],
        item_name: params[:item_name],
        unlink: true # remove collaborator link
      }
      if @processor.status
        u_params[:status] = 'processing'
        u_params[:message] = 'Successfully reviewed submission package. It is ready to be processed for archiving'
      else
        u_params[:status] = 'review_failed'
        u_params[:message] = @processor.errors
      end
      Box::InformUserJob.perform_now(u_params)
    end
end

