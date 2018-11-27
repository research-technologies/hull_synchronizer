RSpec.describe IngestWorkflowMonitorJob do
  let(:workflow) { double }
  let(:params) {{
    item_id: 'item_id',
    item_name: 'test_dir',
    source_dir: 'test_dir',
    number_of_works: 10
  }}
  let(:ingest_wf_monitor) { described_class.new('id', params) }

  describe 'workflow' do
    before do
      allow(IngestWorkflow).to receive(:find).and_return(workflow)
    end

    context 'workflow has already finished' do
      before do
        allow(workflow).to receive(:failed?).and_return(false)
        allow(workflow).to receive(:finished?).and_return(true)
        allow(workflow).to receive(:mark_as_stopped)

        allow(ingest_wf_monitor).to receive(:log_failure)
        allow(ingest_wf_monitor).to receive(:inform_user)
        allow(ingest_wf_monitor).to receive(:failed?).and_return(true)
      end
      it 'returns without running continue or retry' do
        expect(ingest_wf_monitor).not_to receive(:continue)
        expect(ingest_wf_monitor).not_to receive(:retry_later)
        ingest_wf_monitor.perform_now
      end
    end

    context 'failed workflow with failed event' do
      before do
        allow(workflow).to receive(:failed?).and_return(true)
        allow(workflow).to receive(:finished?).and_return(false)
        allow(workflow).to receive(:mark_as_stopped)
        allow(ingest_wf_monitor).to receive(:log_failure)
        allow(ingest_wf_monitor).to receive(:inform_user)
        allow(ingest_wf_monitor).to receive(:failed?).and_return(true)

      end
      it 'returns without running continue or retry' do
        expect(ingest_wf_monitor).not_to receive(:continue)
        expect(ingest_wf_monitor).not_to receive(:retry_later)
        ingest_wf_monitor.perform_now
      end
    end

    context 'failed workflow has retry event' do
      before do
        allow(workflow).to receive(:failed?).and_return(false)
        allow(workflow).to receive(:finished?).and_return(false)

        allow(ingest_wf_monitor).to receive(:retry?).and_return(true)
      end
      it 'performs the job' do
        expect(ingest_wf_monitor).to receive(:continue)
        expect(ingest_wf_monitor).to receive(:retry_later)
        ingest_wf_monitor.perform_now
      end
    end
  end
end
