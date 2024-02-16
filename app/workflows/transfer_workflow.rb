class TransferWorkflow < Gush::Workflow
  attr_reader :number_of_files

  # @params params [Hash] supply any params needed to start the first job
  def configure(params)
    starting = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    #STDERR.puts("==================== Transfer Workflow CONFIGURE called =========================")
    #STDERR.puts(" With thses params: #{params} ")

    item_path = params.fetch(:item_path) #TODO test and make safe

    run Fs::TransferDirJob, params: params

    ending = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    elapsed = ending - starting
    #STDERR.puts("TransferWorkflow.configure took #{elapsed}")
  end

end
