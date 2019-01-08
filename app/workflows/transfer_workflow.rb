class TransferWorkflow < Gush::Workflow
  attr_reader :number_of_files

  # @params params [Hash] supply any params needed to start the first job
  def configure(params)
    item_list = params.fetch(:item_list, {})
    @number_of_files = item_list.size
    item_list.each do |file_id, relative_path|
      job_params = {
        item_id: file_id,
        relative_path: relative_path
      }
      run Box::TransferFileJob, params: job_params
    end
  end

end
