class ReviewWorkflow < Gush::Workflow

  def configure(params)
    # @params params [Hash] contain item_name, item_id, item_list and source_dir
    run ReviewSubmissionJob, params: params
    # output payload has event, message, message_text, status
    #   item_id, item_name, source_dir, number_of_works
    run StartIngestJob, after: ReviewSubmissionJob
  end

end
