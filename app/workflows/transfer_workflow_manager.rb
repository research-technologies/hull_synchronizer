require 'box'
require 'file_locations'

class TransferWorkflowManager
  attr_accessor :flow
  attr_reader :params, :workflow_params

  def initialize(params: {})
    @params = params
    @base_path = "#{params[:item_name]}__#{Time.now.strftime('%FT%H-%M-%S-%N')}"
    inform_user
    start_transfer_workflow
    monitor
  end

  private

  def start_transfer_workflow
    @workflow_params = {
      item_name: params[:item_name],
      item_id: params[:item_id],
      item_list: list_files,
      source_dir: File.join(FileLocations.local_box_dir, @base_path)
    }
    @flow = TransferWorkflow.create(workflow_params)
    flow.start!
    @workflow_params[:workflow_id] = flow.id
  end

  def list_files
    # get list of files in folder from box
    b = Box::Api.new
    b.list_folder(@params[:item_id], base_path: @base_path)
  end

  # Monitor the workflow for retry events
  #  delay start to give the start and approve jobs time to run
  def monitor
    # sleep(60)
    # TransferWorkflowMonitorJob.perform_now(workflow_params)
    TransferWorkflowMonitorJob.set(wait: 1.minute).perform_later(workflow_params)
  end

  def inform_user
    # params need to cointain item_id, item_name, status, message, unlink
    u_params = {item_id: params[:item_id], item_name: params[:item_name]}
    u_params[:status] = 'transfering'
    u_params[:unlink] = false # do not remove collaborator link
    u_params[:message] = 'Starting file transfer'
    Box::InformUserJob.perform_later(u_params)
  end

end
