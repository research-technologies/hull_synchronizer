RSpec.describe IngestWorkflowManager do
  let(:workflow) { double }

  describe 'Workflow Manager' do
    before do
      allow(IngestWorkflow).to receive(:create).and_return(workflow)
      allow(workflow).to receive(:start!)
      allow(workflow).to receive(:id).and_return('id')
      allow(IngestWorkflowMonitorJob).to receive(:set).with(wait: 1.minute).and_return(IngestWorkflowMonitorJob)
      allow(IngestWorkflowMonitorJob).to receive(:perform_later)
    end
    it 'sets up the workflow' do
      expect(IngestWorkflow).to receive(:create).with({})
      expect(IngestWorkflowMonitorJob).to receive(:set).with(wait: 1.minute)
      expect(IngestWorkflowMonitorJob).to receive(:perform_later).with(workflow_id: 'id')
      described_class.new(params: {})
    end
  end
end
