require 'box'
require 'synchronizer_file_locations'

class TransferWorkflowManager
  attr_accessor :flow
  attr_reader :params, :workflow_params
  include SynchronizerFileLocations

  def initialize(params: {})
    @params = params
    @base_path = "#{params[:item_name]}__#{Time.now.strftime('%FT%H-%M-%S-%N')}"
    @workflow_params = get_workflow_params
    inform_user
    @flow = TransferWorkflow.create(workflow_params)
    flow.start!
    monitor
  end

  def get_workflow_params
    {
      item_name: params[:item_name],
      item_id: params[:item_id],
      item_list: list_files,
      source_dir: File.join(local_box_dir, @base_path)
    }
  end

  def list_files
    # get list of files in folder from box
    b = Box::Api.new
    b.list_folder(@params[:item_id], base_path: @base_path)
  end

  # Monitor the workflow for retry events
  #  delay start to give the start and approve jobs time to run
  def monitor
    TransferWorkflowMonitorJob.set(wait: 5.minute).perform_later(flow.id, workflow_params)
  end

  def inform_user
    # params need to cointain item_id, item_name, status, message, unlink
    u_params = {item_id: params[:item_id], item_name: params[:item_name]}
    u_params[:status] = 'transfering'
    u_params[:unlink] = false # do not remove collaborator link
    u_params[:message] = 'Starting file transfer'
    Box::InformUserJob.perform_now(u_params)
  end
end
