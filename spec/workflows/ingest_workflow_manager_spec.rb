RSpec.describe IngestWorkflowManager do
  let(:workflow) { double }
  let(:params) {{
    item_id: 'item_id',
    item_name: 'test_dir',
    source_dir: 'test_dir',
    number_of_works: 10
  }}

  describe 'Workflow Manager' do
    before do
      allow(IngestWorkflow).to receive(:create).and_return(workflow)
      allow(workflow).to receive(:start!)
      allow(workflow).to receive(:id).and_return('id')
      allow(IngestWorkflowMonitorJob).to receive(:set).with(wait: 1.minute).and_return(IngestWorkflowMonitorJob)
      allow(IngestWorkflowMonitorJob).to receive(:perform_later).with('id', params)
    end
    it 'sets up the workflow' do
      expect(IngestWorkflow).to receive(:create).with(params)
      expect(IngestWorkflowMonitorJob).to receive(:set).with(wait: 1.minute)
      expect(IngestWorkflowMonitorJob).to receive(:perform_later).with('id', params)
      described_class.new(params: params)
    end
  end
end
