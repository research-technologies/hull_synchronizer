class IngestWorkflowManager
  attr_accessor :flow

  # @params Hash of params. Required params are
  #   item_id, item_name, source_dir, number_of_works
  def initialize(params: {})
    @flow = IngestWorkflow.create(params)
    flow.start!
    monitor
  end

  # Monitor the workflow for retry events
  #  delay start to give the start and approve jobs time to run
  def monitor
    IngestWorkflowMonitorJob.set(wait: 1.minute).perform_later(flow.id)
  end
end
