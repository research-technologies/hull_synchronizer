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
    @number_of_works = @processor.row_count
    inform_user
    build_output
    fail! if @processor.status == false and @processor.errors.any?
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
      if @processor.status == false and @processor.errors.any?
        msg = 'Submission package has errors'
        event = 'failed'
      else
        msg = 'Successfully reviewed submission package. It is ready to be processed'
        event = 'success'
      end
      output(
        event: event,
        message: Array(msg) + Array(@processor.errors),
        source_dir: params[:source_dir],
        number_of_works: @number_of_works,
        status: @processor.status,
        item_id: params[:item_id],
        item_name: params[:item_name],
      )
    end

    def inform_user
      # params need to contain item_id, item_name, status, message, unlink
      u_params = {
        item_id: params[:item_id],
        item_name: params[:item_name]
      }
      if @processor.status == false and @processor.errors.any?
        u_params[:status] = 'review_failed'
        u_params[:message] = @processor.errors
        u_params[:unlink] = true # remove collaborator link
      else
        u_params[:status] = 'processing'
        u_params[:message] = ['Successfully reviewed submission package. It is ready to be processed for archiving']
        if @processor.errors.any?
          u_params[:message] << "Warning:"
          u_params[:message] += Array(@processor.errors)
        end
        u_params[:unlink] = false # do not remove collaborator link
      end
      #Box::InformUserJob.perform_later(u_params)
    end
end

