class TransferWorkflow < Gush::Workflow

  # @params params [Hash] supply any params needed to start the first job
  def configure(params)
    params.fetch(:item_list, {}).each do |file_id, relative_path|
      job_params = {
        item_id: file_id,
        relative_path: relative_path
      }
      run Box::TransferFileJob, params: job_params
    end
  end

end
