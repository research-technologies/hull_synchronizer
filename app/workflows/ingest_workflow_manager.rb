class IngestWorkflowManager
  attr_accessor :flow

  def initialize(params: {})
    @flow = IngestWorkflow.create(params)
    flow.start!
    monitor
  end

  # Monitor the workflow for retry events
  #  delay start to give the approve / start jobs time to run
  def monitor
    IngestWorkflowMonitorJob.set(wait: 1.minute).perform_later(workflow_id: flow.id)
  end
end
