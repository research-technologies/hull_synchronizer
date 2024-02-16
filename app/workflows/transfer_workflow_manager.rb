require 'fs'
require 'file_locations'

class TransferWorkflowManager
  attr_accessor :flow
  attr_reader :params, :workflow_params

  def initialize(params: {})
    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    #STDERR.puts("==================== Transfer Workflow MANAGER has been initialized =========================")
    @params = params
    @base_path = "#{params[:item_name]}__#{Time.now.strftime('%FT%H-%M-%S-%N')}"
    inform_user
    start_transfer_workflow
    monitor
    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = ending - starting
    #STDERR.puts("TransferWorkflowManager.initialize took #{elapsed}")
  end

  private
  def start_transfer_workflow
    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    @workflow_params = {
      item_name: params[:item_name],
      item_id: params[:item_id],
      item_path: params[:item_path],
      item_list: list_files,
      source_dir: File.join(FileLocations.local_ready_dir, @base_path)
    }
    @flow = TransferWorkflow.create(workflow_params) 

    tw_create = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = tw_create - starting
    #STDERR.puts(" TransferWorkflow.create in #{elapsed}")

    flow.start!

    flow_started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = flow_started - starting
    #STDERR.puts(" Flow.start in #{elapsed}")

    @workflow_params[:workflow_id] = flow.id
    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = ending - starting
    #STDERR.puts("start_transfer_workflow took #{elapsed}")
  end

#  def list_files
#    # get list of files in folder from box
#    b = Box::Api.new
#    b.list_folder(@params[:item_id], base_path: @base_path)
#  end

  def list_files
    # get list of files in folder from box
    STDERR.puts "LIST FILES in #{FileLocations.local_ready_dir}"
    Dir[FileLocations.local_ready_dir]
  end

  # Monitor the workflow for retry events
  #  delay start to give the start and approve jobs time to run
  def monitor
    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    # sleep(60)
    # TransferWorkflowMonitorJob.perform_now(workflow_params)
    TransferWorkflowMonitorJob.set(wait: 1.minute).perform_later(workflow_params)
    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = ending - starting
    #STDERR.puts("monitor took #{elapsed}")
  end

  def inform_user
    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    # params need to cointain item_id, item_name, status, message, unlink
    u_params = {item_id: params[:item_id], item_name: params[:item_name]}
    u_params[:status] = 'transfering'
    u_params[:unlink] = false # do not remove collaborator link
    u_params[:message] = 'Starting file transfer'
#    Box::InformUserJob.perform_later(u_params)
    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = ending - starting
    #STDERR.puts("inform_user #{elapsed}")
  end

end
